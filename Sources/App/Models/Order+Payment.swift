import FluentMySQL
import Vapor

extension Order {
    final class Payment: Content, MySQLModel, Migration, Parameter {
        var id: Int?
        
        let orderID: Order.ID
        let paymentMethod: String
        var paidTotal: Int
        var refundedTotal: Int
        
        public static func prepare(on connection: MySQLConnection) -> Future<Void> {
            return Database.create(self, on: connection) { builder in
                try addProperties(to: builder)
                try builder.addReference(from: \.orderID, to: \Order.id)
            }
        }
    }
}
