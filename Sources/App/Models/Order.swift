import FluentMySQL
import Vapor

final class Order: Content, MySQLModel, Migration {
    var id: Int?
    
    var userID: Int?
    var comment: String?
    var status: Order.Status
    var paymentStatus: Order.PaymentStatus
    var paidTotal: Int
    var refundedTotal: Int
    
    init(from decoder: Decoder) throws {
        fatalError()
    }
    
    var guest: Bool { return self.userID == nil }
    
    func total(with executor: DatabaseConnectable) -> Future<Int> {
        return Future.flatMap(on: executor) {
            return try Item.query(on: executor).join(field: \OrderItem.itemID).filter(OrderItem.self, \.orderID == self.requireID()).sum(\.total)
        }.map(to: Int.self) { Int($0) }
    }
}
