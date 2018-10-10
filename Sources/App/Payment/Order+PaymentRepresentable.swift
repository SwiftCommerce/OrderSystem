import Transaction
import Service
import Fluent
import Vapor

extension Container {
    func databaseConnection<Database>(to database: DatabaseIdentifier<Database>?) -> Future<Database.Connection> {
        guard let database = database else {
            let error = FluentError(identifier: "noDatabaseID", reason: "Attempted to get database connection without a Database ID")
            return self.future(error: error)
        }
        
        do {
            return try self.connectionPool(to: database).withConnection { connection in self.future(connection) }
        } catch let error {
            return self.future(error: error)
        }
    }
}

extension Order: PaymentRepresentable {
    typealias ProviderPayment = [String: String]
    
    func payment<Method, ID>(
        on container: Container,
        with method: Method,
        externalID: ID?
    ) -> EventLoopFuture<Order.Payment> where Method : PaymentMethod {
        return container.databaseConnection(to: .mysql).flatMap { connection in
            let payment = try Order.Payment(
                orderID: self.requireID(),
                paymentMethod: Method.slug,
                paidTotal: self.paidTotal,
                refundedTotal: self.refundedTotal
            )
            if let external = externalID {
                payment.externalID = String(describing: external)
            }
            
            return payment.save(on: connection)
        }
    }
    
    func fetchPayment(on container: Container) -> EventLoopFuture<Order.Payment> {
        return container.databaseConnection(to: .mysql).flatMap { connection in
            let id = try self.requireID()
            let error = Abort(.notFound, reason: "No order payment found for order with ID '" + String(describing: id) +  "'")
            return Order.Payment.query(on: connection).filter(\.orderID == id).first().unwrap(or: error)
        }
    }
}
