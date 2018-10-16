import FluentMySQL
import Vapor

final class Order: Content, MySQLModel, Migration, Parameter {
    var id: Int?
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    
    var userID: Int?
    var accountID: Int?
    var comment: String?
    var status: Order.Status
    var paymentStatus: Order.PaymentStatus
    var paidTotal: Int
    var refundedTotal: Int
    var currency: String
    
    // Costumer and address data
    var firstname: String?
    var lastname: String?
    var company: String?
    var email: String?
    var phone: String?
    
    // Billing address
    var street: String?
    var street2: String?
    var zip: String?
    var city: String?
    var country: String?

    // Shipping address
    var shippingStreet: String?
    var shippingStreet2: String?
    var shippingZip: String?
    var shippingCity: String?
    var shippingCountry: String?
    
    
    
    /// This is the method called for new orders.
    init() {
        self.status = .open
        self.paymentStatus = .open
        self.paidTotal = 0
        self.refundedTotal = 0
        self.currency = "USD"
    }
    
    var guest: Bool { return self.userID == nil }
    
    func total(with executor: DatabaseConnectable) -> Future<Int> {
        return Future.flatMap(on: executor) {
            return try Item.query(on: executor).filter(\.orderID == self.requireID()).all().map(to: Int.self) { items in
                return items.reduce(0) { $0 + $1.total }
            }
        }
    }
    
    func tax(with executor: DatabaseConnectable) -> Future<Int> {
        return executor.eventLoop.newSucceededFuture(result: 0)
/*        return Future.flatMap(on: executor) {
            return try Item.query(on: executor).filter(\.orderID == self.requireID()).sum(\.tax)
        }.map(to: Int.self) { Int($0) }*/
    }
    
    func items(with executor: DatabaseConnectable)throws -> Future<[Item]> {
        return try Item.query(on: executor).filter(\.orderID == self.requireID()).all()
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

extension Array where Iterator.Element == Order {
    
    func response(on request: Request) throws -> Future<[Order.Response]> {
        return try self.map({ try $0.response(on: request) }).flatten(on: request)
    }
}

extension Future where T == [Order] {
    
    func response(on request: Request) throws -> Future<[Order.Response]> {
        return self.flatMap(to: [Order.Response].self, { (this) in
            return try this.response(on: request)
        })
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
        return try map(to: Response.self, self.total(with: request), self.tax(with: request), self.items(with: request)) { total, tax, items in
            return Response(
                id: self.id, userID: self.userID, comment: self.comment, status: self.status, paymentStatus: self.paymentStatus,
                paidTotal: self.paidTotal, refundedTotal: self.refundedTotal, total: total, tax: tax, guest: self.guest,
                items: items.map { item in item.orderResponse }
            )
        }
    }
}
