import TransactionPayPal
import Fluent
import PayPal

typealias PayPalPayment = TransactionPayPal.PayPalPayment<Order, Order.Payment>
typealias PayPalController = PaymentController<PayPalPayment>

extension Order.Payment: ExecutablePayment {
    var total: Int {
        let shipping: Int? = (self.shipping ?? 0) - (self.shippingDiscount ?? 0)
        let fees: Int? = self.tax + self.handling + shipping + self.insurence + self.giftWrap
        return self.subtotal + (fees ?? 0)
    }
}

extension Order: PayPalPaymentRepresentable {
    func paypal(on container: Container, content: PaymentGenerationContent) -> EventLoopFuture<PayPal.Payment> {
        return container.databaseConnection(to: Order.defaultDatabase).flatMap { connection in
            let config = try container.make(GlobalConfig.self)
            return self.paypal(on: connection, content: content, config: config)
        }
    }
    
    func paypal(on conn: DatabaseConnectable, content: PaymentGenerationContent, config: GlobalConfig) -> Future<PayPal.Payment> {
        let id: Order.ID
        do {
            id = try self.requireID()
        } catch let error {
            return conn.future(error: error)
        }
        
        let currency = Currency(code: content.currency) ?? .usd
        let shipping = Address.query(on: conn).filter(\.orderID == id).filter(\.shipping == true).first()
        let items = Item.query(on: conn).filter(\.orderID == id).all()
        let order = Order.query(on: conn).filter(\.id == id).first()
        
        return map(shipping, items, order) { shipping, items, order -> PayPal.Payment in
            let address: PayPal.Address?
            let recipient = order?.firstname + order?.lastname
            if let street = shipping?.street, let city = shipping?.city, let country = shipping?.country, let zip = shipping?.zip {
                address = try PayPal.Address(
                    recipientName: recipient,
                    defaultAddress: false,
                    line1: street,
                    line2: shipping?.street2,
                    city: city,
                    state: shipping?.state,
                    countryCode: country,
                    postalCode: zip,
                    phone: order?.phone,
                    type: nil
                )
            } else {
                address = nil
            }
            
            let listItems = try items.map { item in
                return try PayPal.Payment.Item(
                    quantity: String(describing: item.quantity),
                    price: currency.amount(for: item.price),
                    currency: currency,
                    sku: item.sku,
                    name: item.name,
                    description: item.description,
                    tax: currency.amount(for: item.tax)
                )
            }
            let list = try PayPal.Payment.ItemList(items: listItems, address: address, phoneNumber: nil)
            
            
            let subtotal = items.map { item in item.total }.reduce(0, +)
            let tax = items.map { item in item.tax }.reduce(0, +)
            
            let details = try DetailedAmount.Detail(
                subtotal: currency.amount(for: subtotal),
                shipping: currency.amount(for: content.shipping),
                tax: currency.amount(for: tax),
                handlingFee: currency.amount(for: content.handling),
                shippingDiscount: currency.amount(for: content.shippingDiscount),
                insurance: currency.amount(for: content.insurence),
                giftWrap: currency.amount(for: content.giftWrap)
            )
            
            let shipping: Int? = (content.shipping ?? 0) - (content.shippingDiscount ?? 0)
            let fees = shipping + content.handling + content.insurence + content.giftWrap
            let total = subtotal + tax + (fees ?? 0)
            let amount = try DetailedAmount(
                currency: currency,
                total: currency.amount(for: total),
                details: details
            )
            
            let transaction = try PayPal.Payment.Transaction(
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
            
            return try PayPal.Payment(
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
}
