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

    func total(on container: Container, currency: String) -> Future<Int> {
        return container.databaseConnection(to: .mysql).flatMap { conn -> Future<Int> in
            return try self.items(with: conn).flatMap { items in
                return container.products(for: items)
            }.map { merch -> Int in
                return try merch.reduce(0) { total, merch in
                    let (item, product) = merch
                    guard let price = product.prices?.filter({ $0.currency.lowercased() == currency.lowercased() }).first else {
                        throw Abort(.failedDependency, reason: "No price for product '\(product.sku)' with currency '\(currency)'")
                    }
                    return total + item.total(for: price.cents)
                }
            }
        }
    }

    func tax(on container: Container, currency: String) -> Future<Int> {
        return container.databaseConnection(to: .mysql).flatMap { conn -> Future<Int> in
            return try self.items(with: conn).flatMap { items in
                return container.products(for: items)
            }.map { merch -> Int in
                return try merch.reduce(0) { total, merch in
                    let (item, product) = merch
                    guard let price = product.prices?.filter({ $0.currency.lowercased() == currency.lowercased() }).first else {
                        throw Abort(.failedDependency, reason: "No price for product '\(product.sku)' with currency '\(currency)'")
                    }
                    return total + item.tax(for: price.cents)
                }
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
        var id, userID, total, tax: Int?
        var comment, authToken, firstname, lastname, company, email, phone: String?
        var status: Order.Status
        var paymentStatus: Order.PaymentStatus
        var paidTotal, refundedTotal: Int
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

        let total: Future<Int?>
        let tax: Future<Int?>
        if let currency = try request.content.syncGet(String?.self, at: "currency") {
            total = self.total(on: request, currency: currency).map { $0 }
            tax = self.tax(on: request, currency: currency).map { $0 }
        } else {
            total = request.future(nil)
            tax = request.future(nil)
        }
        
        return try map(
            total,
            tax,
            self.items(with: request),
            Address.query(on: request).filter(\.orderID == self.requireID()).filter(\.shipping == true).first(),
            Address.query(on: request).filter(\.orderID == self.requireID()).filter(\.shipping == false).first()
        ) { total, tax, items, shipping, billing in
            let email = self.email?.hasSuffix("ordersystem.example.com") ?? false ? nil : self.email
            return Response(
                id: self.id, userID: self.userID, total: total, tax: tax, comment: self.comment, authToken: token, firstname: self.firstname,
                lastname: self.lastname, company: self.company, email: email, phone: self.phone, status: self.status,
                paymentStatus: self.paymentStatus, paidTotal: self.paidTotal, refundedTotal: self.refundedTotal, guest: self.guest,
                items: items.map { item in item.orderResponse }, shippingAddress: shipping?.response, billingAddress: billing?.response
            )
        }
    }
}
