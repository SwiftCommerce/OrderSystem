import FluentMySQL
import Vapor

extension Order {
    final class Payment: Content, MySQLModel, Migration, Parameter {
        var id: Int?
        
        let orderID: Order.ID
        let paymentMethod: String
        var paidTotal: Int
        var refundedTotal: Int
        
        init(orderID: Order.ID, paymentMethod: String, paidTotal: Int, refundedTotal: Int) {
            self.orderID = orderID
            self.paymentMethod = paymentMethod
            self.paidTotal = paidTotal
            self.refundedTotal = refundedTotal
        }

        init(from decoder: Decoder)throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeIfPresent(Int.self, forKey: .id)
            self.orderID = try container.decode(Order.ID.self, forKey: .orderID)
            self.paymentMethod = try container.decode(String.self, forKey: .paymentMethod)
            self.paidTotal = try container.decode(Int.self, forKey: .paidTotal)
            self.refundedTotal = try container.decode(Int.self, forKey: .refundedTotal)
        }
        
        public static func prepare(on connection: MySQLConnection) -> Future<Void> {
            return Database.create(self, on: connection) { builder in
                try addProperties(to: builder)
                try builder.addReference(from: \.orderID, to: \Order.id)
            }
        }
    }
}

