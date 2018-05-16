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
}
