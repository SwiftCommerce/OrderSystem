import Transaction
import FluentMySQL
import Vapor

extension Order.Payment {
    var total: Int {
        let shipping: Int? = (self.shipping ?? 0) - (self.shippingDiscount ?? 0)
        let fees: Int? = self.tax + self.handling + shipping + self.insurence + self.giftWrap
        return self.subtotal + (fees ?? 0)
    }
}

extension Order: PaymentRepresentable {
    typealias ProviderPayment = [String: String]

    func payment<Method, ID>(
        on container: Container,
        with method: Method,
        content: PaymentGenerationContent,
        externalID: ID?
    ) -> EventLoopFuture<Order.Payment> where Method : PaymentMethod {
        return flatMap(
            container.databaseConnection(to: .mysql) as Future<MySQLConnection>,
            self.calculateTotal(on: container, currency: content.currency),
            self.tax(on: container, currency: content.currency)
        ) { (connection: MySQLDatabase.Connection, total: Int, tax: TaxCalculator.Result) -> Future<Order.Payment> in
            self.total = total
            
            let payment = try Order.Payment(
                orderID: self.requireID(),
                paymentMethod: Method.slug,
                currency: content.currency,
                subtotal: total,
                paid: self.paidTotal,
                refunded: self.refundedTotal
            )
            if let external = externalID {
                payment.externalID = String(describing: external)
            }
            payment.tax = NSDecimalNumber(decimal: tax.total).intValue
            payment.shipping = content.shipping
            payment.handling = content.handling
            payment.shippingDiscount = content.shippingDiscount
            payment.insurence = content.insurence
            payment.giftWrap = content.giftWrap
            
            return self.update(on: connection).transform(to: connection).flatMap(payment.create)
        }
    }

    func fetchPayment(on container: Container) -> EventLoopFuture<Order.Payment> {
        return container.databaseConnection(to: .mysql).flatMap { connection in
            if let request = container as? Request {
                guard let user = try request.get(payload, as: User.self) else { throw Abort(.unauthorized) }
                guard self.email == user.email else { throw Abort(.notFound) }
            }

            let id = try self.requireID()
            let error = Abort(.notFound, reason: "No order payment found for order with ID '" + String(describing: id) +  "'")
            return Order.Payment.query(on: connection).filter(\.orderID == id).first().unwrap(or: error)
        }
    }
}
