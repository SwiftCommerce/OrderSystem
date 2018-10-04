import JWTMiddleware
import Fluent
import Vapor

final class PaymentController: RouteCollection {
    func boot(router: Router) throws {
        let orderRoute = router.grouped(JWTVerificationMiddleware()).grouped("orders", "payments")
        
        orderRoute.post(NewStripePaymentAttempt.self, use: pay)
    }
    
    func pay(_ request: Request, _ paymentParameters: NewStripePaymentAttempt)throws -> Future<PaymentMethodReturn> {
        
        guard let orderID = paymentParameters.orderID else {
            throw Abort(.badRequest, reason: "No order id given.")
        }
        
        guard let token = paymentParameters.token else {
            throw Abort(.badRequest, reason: "No token given.")
        }
        
        let user:User = try request.get("skelpo-payload")!
        
        
        return Order.query(on: request).filter(\.id == orderID).filter(\.userID == user.id).first().flatMap(to: PaymentMethodReturn.self) { order_ in
            guard let order = order_ else {
                throw Abort(.badRequest, reason: "No order found.")
            }
            return order.total(with: request).flatMap(to: PaymentMethodReturn.self) { total in
                let stripeCC: StripeCCPaymentMethod = StripeCCPaymentMethod(request: request)
                
                return try stripeCC.payForOrder(order: order, userId: user.id, amount: total, params: token)
            }
            
        }
        /*
        return order.save(on: request).flatMap(to: Order.Response.self) { order in
            var savingItems:[Future<Item>] = []
            for item in items {
                let i = Item(orderID: order.id!, sku: item.sku, price: item.price, quantity: item.quantity).save(on: request)
                savingItems.append(i)
            }
            return savingItems.flatten(on: request).flatMap(to: Order.Response.self) { items in
                return try order.response(on: request)
            }
        }*/
    }
    
}


protocol NewPaymentAttempt: Content {
    var orderID: Int? {get}
}

struct NewStripePaymentAttempt: NewPaymentAttempt, Content {
    var token: String?
    var orderID: Int?
}
