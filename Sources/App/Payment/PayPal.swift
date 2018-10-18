import TransactionPayPal
import Fluent
import PayPal

typealias PayPalPayment = TransactionPayPal.PayPalPayment<Order, Order.Payment>
typealias PayPalController = PaymentController<PayPalPayment>

extension Order.Payment: ExecutablePayment {
    var total: Int {
        let fees: Int? = self.shipping + self.handling + self.shippingDiscount + self.insurence + self.giftWrap
        return self.subtotal + fees ?? self.subtotal
    }
}

extension Order.Payment: PayPalPaymentRepresentable {
    func paypal(on conn: DatabaseConnectable) -> Future<PayPal.Payment> {
        let currency = Currency(code: self.currency) ?? .usd
        let shipping = Address.query(on: conn).filter(\.orderID == self.orderID).filter(\.shipping == true).first()
        let items = Item.query(on: conn).filter(\.orderID == self.orderID).all()
        let order = Order.query(on: conn).filter(\.id == self.orderID).first()
        
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
            
            
            let subtotal = items.map { item in item.price * item.quantity }.reduce(0, +)
            let tax = items.map { item in item.tax }.reduce(0, +)
            
            let details = try DetailedAmount.Detail(
                subtotal: currency.amount(for: subtotal),
                shipping: currency.amount(for: self.shipping),
                tax: currency.amount(for: tax),
                handlingFee: currency.amount(for: self.handling),
                shippingDiscount: currency.amount(for: self.shippingDiscount),
                insurance: currency.amount(for: self.insurence),
                giftWrap: currency.amount(for: self.giftWrap)
            )
            
            let total = subtotal + tax
            let amount = try DetailedAmount(
                currency: Currency(code: self.currency) ?? .usd,
                total: currency.amount(for: total),
                details: details
            )
            
            let transaction = try PayPal.Payment.Transaction(
                amount: amount,
                payee: Payee(email: "placeholder@example.com", merchant: nil, metadata: nil),
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
                redirects: Redirects(return: "https://placeholder.com/success", cancel: "https://placeholder.com/fail")
            )
        }
    }
}
