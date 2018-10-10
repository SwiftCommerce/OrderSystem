import FluentMySQL
import Vapor

extension Order {
    final class Payment: Content, MySQLModel, Migration, Parameter {
        var id: Int?
        
        let orderID: Order.ID
        let paymentMethod: String
        var externalID: String?
        var paidTotal: Int
        var refundedTotal: Int
        
        init(orderID: Order.ID, paymentMethod: String, paidTotal: Int, refundedTotal: Int) {
            self.orderID = orderID
            self.paymentMethod = paymentMethod
            self.paidTotal = paidTotal
            self.refundedTotal = refundedTotal
        }
        
        public static func prepare(on connection: MySQLConnection) -> Future<Void> {
            return Database.create(self, on: connection) { builder in
                try addProperties(to: builder)
                builder.reference(from: \.orderID, to: \Order.id)
            }
        }
    }
}
