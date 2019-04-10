import TransactionPayPal
import Countries
import Fluent
import PayPal

typealias PayPalPayment = TransactionPayPal.PayPalPayment<Order, Order.Payment>
typealias PayPalController = PaymentController<PayPalPayment>

extension Order.Payment: ExecutablePayment {}
extension Product {
    typealias List = [Item.ID: (product: Product, price: Price)]
}

extension Order: PayPalPaymentRepresentable {
    func paypal(on container: Container, content: PaymentGenerationContent) -> EventLoopFuture<PayPal.Payment> {
        return container.databaseConnection(to: Order.defaultDatabase).flatMap { connection in
            let config = try container.make(OrderService.self)
            return self.paypal(on: connection, content: content, config: config, container: container)
        }
    }
    
    func paypal(
        on conn: DatabaseConnectable,
        content: PaymentGenerationContent,
        config: OrderService,
        container: Container
    ) -> Future<PayPal.Payment> {
        guard let id = self.id else {
            return conn.future(error: FluentError(identifier: "idRequired", reason: "\(Order.self) does not have an identifier."))
        }
        
        let currency = Currency(code: content.currency) ?? .usd
        let items = Item.query(on: conn).filter(\.orderID == id).all()
        let products = items.flatMap { self.products(on: container, for: $0, currency: currency.rawValue) }
        
        return flatMap(self.tax(on: container, currency: currency.rawValue), items, products) { tax, items, products -> Future<PayPal.Payment> in
            let itemList = self.items(
                on: conn, with: container, order: id, items: items, currency: currency, tax: tax, products: products
            )
            return itemList.map { list in
                let tax = NSDecimalNumber(decimal: tax.total).intValue
                let subtotal = items.compactMap { item -> Int? in
                    guard let id = item.id, let price = products[id]?.price.cents else { return nil }
                    return item.total(for: price)
                }.reduce(0, +)
                
                let details = self.details(content: content, subtotal: subtotal, tax: tax, currency: currency)
                let amount = self.amount(details: details, content: content, subtotal: subtotal, tax: tax, currency: currency)
                let transaction = try self.transaction(amount: amount, list: list, config: config)
                return try self.payment(transaction: transaction, config: config)
            }
        }
    }
    
    func address(on conn: DatabaseConnectable, with container: Container, order id: Order.ID) -> Future<PayPal.Address?> {
        return App.Address.get(for: id, purpose: .shipping, on: container).map { address in
            guard
                let street = address?.line1, let city = address?.city,
                let country = Country(rawValue: address?.country ?? "nil"), let zip = address?.postalArea
            else { return nil }
            
            let recipient = self.firstname + self.lastname
            return PayPal.Address(
                recipientName: recipient,
                defaultAddress: false,
                line1: street,
                line2: address?.line2,
                city: city,
                state: Province(rawValue: address?.district ?? "nil"),
                country: country,
                postalCode: zip,
                phone: self.phone,
                type: nil
            )
        }
    }
    
    func products(on container: Container, for items: [Item], currency: String) -> Future<Product.List> {
        let repository: ProductRepository
        switch Swift.Result(catching: { try container.make(ProductRepository.self) }) {
        case let .failure(error): return container.future(error: error)
        case let .success(result): repository = result
        }
        
        return repository.get(products: items.map { $0.productID }).map { list in zip(list, items) }.map { elements in
            return try elements.reduce(into: [:]) { list, element in
                guard let product = element.0 else { return }
                let (_, item) = element
                let id = try item.requireID()
                
                guard let price = product.currentPrice(for: currency) else {
                    throw PayPalError(
                        status: .failedDependency,
                        identifier: "noPrice",
                        reason: "No price found for product '\(product.sku)' with currency '\(currency)'"
                    )
                }
                
                list[id] = (product, price)
            }
        }
    }
    
    func items(
        on conn: DatabaseConnectable, with container: Container, order id: Order.ID, items: [Item], currency: Currency,
        tax: TaxCalculator.Result, products: Product.List
    ) -> Future<PayPal.Payment.ItemList> {
        return self.address(on: conn, with: container, order: id).map { address in
            let listItems = try items.compactMap { item -> PayPal.Payment.Item? in
                guard let id = item.id, let (product, price) = products[id], let itemTax = tax.items[id.description] else { return nil }
                let tax = NSDecimalNumber(decimal: itemTax).intValue

                return try PayPal.Payment.Item(
                    quantity: .init(item.quantity),
                    price: .init(currency.amount(for: price.cents)),
                    currency: currency,
                    sku: .init(product.sku),
                    name: .init(product.name),
                    description: .init(product.description),
                    tax: String(describing: currency.amount(for: tax))
                )
            }
            return PayPal.Payment.ItemList(items: listItems, address: address, phoneNumber: nil)
        }
    }
    
    func details(content: PaymentGenerationContent, subtotal: Int, tax: Int, currency: Currency) -> DetailedAmount.Detail {
        return DetailedAmount.Detail(
            subtotal: currency.amount(for: subtotal),
            shipping: currency.amount(for: content.shipping),
            tax: currency.amount(for: tax),
            handlingFee: currency.amount(for: content.handling),
            shippingDiscount: currency.amount(for: content.shippingDiscount),
            insurance: currency.amount(for: content.insurence),
            giftWrap: currency.amount(for: content.giftWrap)
        )
    }
    
    func amount(
        details: DetailedAmount.Detail, content: PaymentGenerationContent, subtotal: Int, tax: Int, currency: Currency
    ) -> PayPal.DetailedAmount {
        let shipping: Int? = (content.shipping ?? 0) - (content.shippingDiscount ?? 0)
        let fees = shipping + content.handling + content.insurence + content.giftWrap
        let total = subtotal + tax + (fees ?? 0)
        
        return DetailedAmount(
            currency: currency,
            total: currency.amount(for: total),
            details: details
        )
    }
    
    func transaction(amount: DetailedAmount, list: PayPal.Payment.ItemList, config: OrderService)throws -> PayPal.Payment.Transaction {
        return PayPal.Payment.Transaction(
            amount: amount,
            payee: Payee(email: config.paypalPayeeEmail, merchant: nil, metadata: nil),
            description: nil,
            payeeNote: nil,
            custom: nil,
            invoice: nil,
            softDescriptor: nil,
            payment: .instantFunding,
            itemList: list,
            notify: nil
        )
    }
    
    func payment(transaction: PayPal.Payment.Transaction, config: OrderService)throws -> PayPal.Payment {
        return PayPal.Payment(
            intent: .sale,
            payer: PaymentPayer(method: .paypal, funding: nil, info: nil),
            context: nil,
            transactions: [transaction],
            experience: nil,
            payerNote: nil,
            redirects: Redirects(return: config.paypalRedirectApprove, cancel: config.paypalRedirectCancel)
        )
    }
}
