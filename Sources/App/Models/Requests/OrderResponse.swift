import ModelResponse
import JWTVapor
import Fluent
import Vapor

extension Order: Respondable {
    struct Result: Vapor.Content {
        var id, userID: Int?
        var createdAt, updatedAt: Date?
        var comment, authToken, firstname, lastname, company, email, phone: String?
        var status: Order.Status
        var paymentStatus: Order.PaymentStatus
        var paidTotal, refundedTotal: Int
        var guest: Bool
        var items: [Item.OrderResponse]
        var payment: Payment?
        var shippingAddress: Address?
        var billingAddress: Address?
    }
    
    func response(on container: Container) -> Future<Order.Result> {
        let token: String
        if let request = container as? Request, let bearer = request.http.headers.bearerAuthorization {
            token = bearer.token
        } else {
            do {
                let signer = try container.make(JWTService.self)
                let user = User(
                    exp: Date.distantFuture.timeIntervalSince1970,
                    iat: Date().timeIntervalSince1970,
                    email: self.email ?? "guest" + UUID().uuidString + "@ordersystem.example.com",
                    id: nil,
                    status: .standard
                )
                token = try signer.sign(user)
            } catch let error {
                return container.future(error: error)
            }
        }
        
        return container.databaseConnection(to: .mysql).flatMap { conn -> Future<Order.Result> in
            
            #warning("Get related addresses from address service")
            return try map(
                self.items(with: conn),
                Payment.query(on: conn).filter(\.orderID == self.requireID()).first()
            ) { items, payment in
                let shipping = try Address(json: nil)
                let billing = try Address(json: nil)
                
                return Result(
                    id: self.id, userID: self.userID, createdAt: self.createdAt, updatedAt: self.updatedAt, comment: self.comment,
                    authToken: token, firstname: self.firstname, lastname: self.lastname, company: self.company, email: self.email,
                    phone: self.phone, status: self.status, paymentStatus: self.paymentStatus, paidTotal: self.paidTotal,
                    refundedTotal: self.refundedTotal, guest: self.guest, items: items.map { item in item.orderResponse },
                    payment: payment, shippingAddress: shipping, billingAddress: billing
                )
            }
        }
    }
}

extension Order {
    
    /// Wraps the address content data, so they `shipping` and `billing` addresses are keyed for the client.
    struct Address: Content {
        let shipping: App.Address?
        let billing: App.Address?
        
        func save(with addresses: AddressRepository, on worker: Worker) -> Future<Void> {
            let shipping = self.shipping.map(addresses.save(address:))?.transform(to: ()) ?? worker.future()
            let billing = self.billing.map(addresses.save(address:))?.transform(to: ()) ?? worker.future()
            
            return [shipping, billing].flatten(on: worker)
        }
    }
}
