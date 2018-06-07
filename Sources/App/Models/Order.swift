import FluentMySQL
import Vapor

final class Order: Content, MySQLModel, Migration, Timestampable, SoftDeletable {
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    
    var id: Int?
    
    var userID: Int?
    var comment: String?
    var status: Order.Status
    var paymentStatus: Order.PaymentStatus
    var paidTotal: Int
    var refundedTotal: Int
    
    /// This is the method called for new orders.
    init() {
        status = .open
        paymentStatus = .open
        paidTotal = 0
        refundedTotal = 0
    }
    
    init(from decoder: Decoder)throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
        self.userID = try container.decodeIfPresent(Int.self, forKey: .userID)
        self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        self.status = try container.decode(Order.Status.self, forKey: .status)
        self.paymentStatus = try container.decode(Order.PaymentStatus.self, forKey: .paymentStatus)
        self.paidTotal = try container.decode(Int.self, forKey: .paidTotal)
        self.refundedTotal = try container.decode(Int.self, forKey: .refundedTotal)
        
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        self.deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
    }
    
    var guest: Bool { return self.userID == nil }
    
    func total(with executor: DatabaseConnectable) -> Future<Int> {
        return Future.flatMap(on: executor) {
            return try Item.query(on: executor).filter(\.orderID == self.requireID()).sum(\.total)
        }.map(to: Int.self) { Int($0) }
    }
    
    func tax(with executor: DatabaseConnectable) -> Future<Int> {
        return Future.flatMap(on: executor) {
            return try Item.query(on: executor).filter(\.orderID == self.requireID()).sum(\.tax)
        }.map(to: Int.self) { Int($0) }
    }
    
    func items(with executor: DatabaseConnectable)throws -> Future<[Item]> {
        return try Item.query(on: executor).filter(\.orderID == self.id).all()
    }
}

extension Order {
    static var createdAtKey: WritableKeyPath<Order, Date?> {
        return \.createdAt
    }
    
    static var updatedAtKey: WritableKeyPath<Order, Date?> {
        return \.updatedAt
    }
    
    static var deletedAtKey: WritableKeyPath<Order, Date?> {
        return \.deletedAt
    }
}

extension Order {
    struct Response: Content {
        var id, userID: Int?
        var comment: String?
        var status: Order.Status
        var paymentStatus: Order.PaymentStatus
        var paidTotal, refundedTotal, total, tax: Int
        var guest: Bool
        var items: [Item.OrderResponse]
    }
    
    func response(on request: Request)throws -> Future<Response> {
        return flatMap(to: Response.self, self.total(with: request), self.tax(with: request)) { total, tax in
            return try self.items(with: request).map(to: Response.self) { items in
                return Response(id: self.id, userID: self.userID, comment: self.comment, status: self.status, paymentStatus: self.paymentStatus, paidTotal: self.paidTotal,
                                refundedTotal: self.refundedTotal, total: total, tax: tax, guest: self.guest, items: items.map { return $0.orderResponse })
            }
            
        }
    }
}
