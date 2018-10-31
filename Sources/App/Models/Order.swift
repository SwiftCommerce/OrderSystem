import FluentMySQL
import JWTVapor
import Vapor

final class Order: Content, MySQLModel, Migration, Parameter {
    var id: Int?
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?

    var status: Order.Status
    var paymentStatus: Order.PaymentStatus
    var paidTotal: Int
    var refundedTotal: Int

    var userID: Int?
    var accountID: Int?
    var comment: String?

    var firstname: String?
    var lastname: String?
    var company: String?
    var email: String?
    var phone: String?


    /// This is the method called for new orders.
    init() {
        self.status = .open
        self.paymentStatus = .open
        self.paidTotal = 0
        self.refundedTotal = 0
    }

    var guest: Bool { return self.userID == nil }

    func total(on container: Container) -> Future<Int> {
        return container.databaseConnection(to: .mysql).flatMap { conn -> Future<Int> in
            return try self.items(with: conn).flatMap { items in
                return container.products(for: items)
            }.map { merch -> Int in
                return merch.reduce(0) { $0 + $1.item.total(for: $1.product.price?.cents ?? 0) }
            }
        }
    }

    func tax(on container: Container) -> Future<Int> {
        return container.databaseConnection(to: .mysql).flatMap { conn -> Future<Int> in
            return try self.items(with: conn).flatMap { items in
                return container.products(for: items)
            }.map { merch -> Int in
                return merch.reduce(0) { $0 + $1.item.tax(for: $1.product.price?.cents ?? 0) }
            }
        }
    }

    func items(with conn: DatabaseConnectable)throws -> Future<[Item]> {
        return try Item.query(on: conn).filter(\.orderID == self.requireID()).all()
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
    struct Response: Vapor.Content {
        var id, userID: Int?
        var comment, authToken, firstname, lastname, company, email, phone: String?
        var status: Order.Status
        var paymentStatus: Order.PaymentStatus
        var paidTotal, refundedTotal, total, tax: Int
        var guest: Bool
        var items: [Item.OrderResponse]
        var shippingAddress: Address.Response?
        var billingAddress: Address.Response?
    }

    func response(on request: Request)throws -> Future<Response> {
        let token: String
        if let bearer = request.http.headers.bearerAuthorization {
            token = bearer.token
        } else {
            let signer = try request.make(JWTService.self)
            guard let email = self.email else { throw Abort(.internalServerError, reason: "Failed to create unique ID email for payment token") }
            let user = User(
                exp: Date.distantFuture.timeIntervalSince1970,
                iat: Date().timeIntervalSince1970,
                email: email,
                id: nil
            )
            token = try signer.sign(user)
        }

        return try map(
            self.total(on: request),
            self.tax(on: request),
            self.items(with: request),
            Address.query(on: request).filter(\.orderID == self.requireID()).filter(\.shipping == true).first(),
            Address.query(on: request).filter(\.orderID == self.requireID()).filter(\.shipping == false).first()
        ) { total, tax, items, shipping, billing in
            let email = self.email?.hasSuffix("ordersystem.example.com") ?? false ? nil : self.email
            return Response(
                id: self.id, userID: self.userID, comment: self.comment, authToken: token, firstname: self.firstname, lastname: self.lastname,
                company: self.company, email: email, phone: self.phone, status: self.status, paymentStatus: self.paymentStatus,
                paidTotal: self.paidTotal, refundedTotal: self.refundedTotal, total: total, tax: tax, guest: self.guest,
                items: items.map { item in item.orderResponse }, shippingAddress: shipping?.response, billingAddress: billing?.response
            )
        }
    }
}
