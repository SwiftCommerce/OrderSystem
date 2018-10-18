import FluentMySQL
import PayPal
import Vapor

extension Order {
    final class Payment {
        var id: Int?
        
        let paymentMethod: String
        let orderID: Order.ID
        var externalID: String?
        var currency: String
        
        var paid: Int
        var refunded: Int
        
        var subtotal: Int
        var shipping: Int?
        var handling: Int?
        var shippingDiscount: Int?
        var insurence: Int?
        var giftWrap: Int?
        
        init(orderID: Order.ID, paymentMethod: String, currency: String, subtotal: Int, paid: Int, refunded: Int) {
            self.orderID = orderID
            self.paymentMethod = paymentMethod
            self.subtotal = subtotal
            self.paid = paid
            self.refunded = refunded
            self.currency = currency
        }
    }
}

extension Order.Payment: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.orderID, to: \Order.id)
        }
    }
}

extension Order.Payment: Content {}
extension Order.Payment: Parameter {}
extension Order.Payment: MySQLModel {}

extension Order.Payment {
    func paypal(on conn: DatabaseConnectable) -> Future<PayPal.Payment> {
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
                    price: String(describing: item.price),
                    currency: Currency(code: self.currency) ?? .usd,
                    sku: item.sku,
                    name: item.name,
                    description: item.description,
                    tax: String(describing: item.tax)
                )
            }
            let list = try PayPal.Payment.ItemList(items: listItems, address: address, phoneNumber: nil)
            
            
            let subtotal = items.map { item in item.price * item.quantity }.reduce(0, +)
            let tax = items.map { item in item.tax }.reduce(0, +)
            
            let details = try DetailedAmount.Detail(
                subtotal: String(describing: subtotal),
                shipping: String(describing: self.shipping),
                tax: String(describing: tax),
                handlingFee: String(describing: self.handling),
                shippingDiscount: String(describing: self.shippingDiscount),
                insurance: String(describing: self.insurence),
                giftWrap: String(describing: self.giftWrap)
            )
            
            let total = subtotal + tax
            let amount = try DetailedAmount(
                currency: Currency(code: self.currency) ?? .usd,
                total: String(describing: total),
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
