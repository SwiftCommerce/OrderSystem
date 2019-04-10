import ModelResponse
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

    func calculateTotal(on container: Container, currency: String) -> Future<Int> {
        return container.databaseConnection(to: .mysql).flatMap { conn in
            return self.items(with: conn)
        }.flatMap { items in
            return try container.make(ProductRepository.self).get(products: items.map { $0.productID }).map { products in
                return try zip(products, items).reduce(0) { total, element in
                    let (product, item) = element
                    let prices = product?.prices?.filter({ $0.currency.lowercased() == currency.lowercased() && $0.active })
                    guard let price = prices?.first else {
                        throw Abort(
                            .failedDependency,
                            reason: "No price for product '\(product?.sku ?? "null")' with currency '\(currency)'"
                        )
                    }
                    
                    return total + item.total(for: price.cents)
                }
            }
        }
    }

    func tax(on container: Container, currency: String) -> Future<TaxCalculator.Result> {
        return TaxCalculator(container: container).calculate(from: (self, currency))
    }

    func items(with conn: DatabaseConnectable) -> Future<[Item]> {
        do {
            return try Item.query(on: conn).filter(\.orderID == self.requireID()).all()
        } catch let error {
            return conn.future(error: error)
        }
    }
}

extension Order {
    static var createdAtKey: TimestampKey? {
        return \.createdAt
    }

    static var updatedAtKey: TimestampKey? {
        return \.updatedAt
    }

    static var deletedAtKey: TimestampKey? {
        return \.deletedAt
    }
}
