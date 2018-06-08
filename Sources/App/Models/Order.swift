import FluentMySQL
import Vapor

final class Order: Content, MySQLModel, Migration, Timestampable, SoftDeletable {
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
    
    var id: Int?
    
    var userID: Int?
    var accountID: Int?
    var comment: String?
    var status: Order.Status
    var paymentStatus: Order.PaymentStatus
    var paidTotal: Int
    var refundedTotal: Int
    
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
        status = .open
        paymentStatus = .open
        paidTotal = 0
        refundedTotal = 0
    }
    
    init(from decoder: Decoder)throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
        self.userID = try container.decodeIfPresent(Int.self, forKey: .userID)
        self.accountID = try container.decode(Int.self, forKey: .accountID)
        self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        self.status = try container.decode(Order.Status.self, forKey: .status)
        self.paymentStatus = try container.decode(Order.PaymentStatus.self, forKey: .paymentStatus)
        self.paidTotal = try container.decode(Int.self, forKey: .paidTotal)
        self.refundedTotal = try container.decode(Int.self, forKey: .refundedTotal)

        self.firstname = try container.decodeIfPresent(String.self, forKey: .firstname)
        self.lastname = try container.decodeIfPresent(String.self, forKey: .lastname)
        self.company = try container.decodeIfPresent(String.self, forKey: .company)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.phone = try container.decodeIfPresent(String.self, forKey: .phone)
        
        self.street = try container.decodeIfPresent(String.self, forKey: .street)
        self.street2 = try container.decodeIfPresent(String.self, forKey: .street2)
        self.zip = try container.decodeIfPresent(String.self, forKey: .zip)
        self.city = try container.decodeIfPresent(String.self, forKey: .city)
        self.country = try container.decodeIfPresent(String.self, forKey: .country)
        
        self.shippingStreet = try container.decodeIfPresent(String.self, forKey: .shippingStreet)
        self.shippingStreet2 = try container.decodeIfPresent(String.self, forKey: .shippingStreet2)
        self.shippingZip = try container.decodeIfPresent(String.self, forKey: .shippingZip)
        self.shippingCity = try container.decodeIfPresent(String.self, forKey: .shippingCity)
        self.shippingCountry = try container.decodeIfPresent(String.self, forKey: .shippingCountry)
        
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        self.deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
    }
    
    var guest: Bool { return self.userID == nil }
    
    func total(with executor: DatabaseConnectable) -> Future<Int> {
        return Future.flatMap(on: executor) {
            return try Item.query(on: executor).filter(\.orderID == self.requireID()).all().map(to: Int.self) { items in
                var total = 0
                for item in items {
                    total = total + item.total
                }
                return total
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
                id: self.id, userID: self.userID, comment: self.comment, status: self.status, paymentStatus: self.paymentStatus, paidTotal: self.paidTotal,
                refundedTotal: self.refundedTotal, total: total, tax: tax, guest: self.guest, items: items.map { item in item.orderResponse }
            )
        }
    }
}
