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
        var payee: String?
        
        var paid: Int
        var refunded: Int
        
        var subtotal: Int
        var tax: Int?
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
