import JWTMiddleware
import Fluent
import Vapor

final class OrderController: RouteCollection {
    func boot(router: Router) throws {
        let orderRoute = router.grouped(JWTVerificationMiddleware()).grouped("orders")
        
        orderRoute.post(OrderContent.self, use: create)
        orderRoute.get(use: all)
        orderRoute.get(Order.parameter, use: get)
    }
    
    func create(_ request: Request, content: OrderContent)throws -> Future<Order.Response> {
        let order = Order()
        let user: User? = try request.get("skelpo-payload")
        
        order.userID = user?.id
        content.populate(order: order)
        let saved = order.save(on: request)

        return saved.flatMap { order -> Future<Order> in
            let id = try order.requireID()
            let items = (content.items ?? []).map { data in data.save(on: request, order: id) }.flatten(on: request)
            let addresses = content.addresses?.save(on: request, order: id) ?? request.future()
            
            return items.and(addresses).transform(to: order)
        }.flatMap { order in
            return try order.response(on: request)
        }
    }
    
    func all(_ request: Request)throws -> Future<[Order.Response]> {
        guard let user = try request.get("skelpo-payload", as: User.self) else {
            throw Abort(.unauthorized, reason: "You must be logged into your account to view past orders.")
        }
        return try Order.query(on: request).filter(\.userID == user.id).all().response(on: request)
    }
    
    
    func get(_ request: Request)throws -> Future<Order.Response> {
        guard
            let user = try request.get("skelpo-payload", as: User.self),
            let rawID = request.parameters.rawValues(for: Order.self).first,
            let id = Int(rawID)
        else {
            throw Abort(.notFound)
        }

        let order = Order.query(on: request).filter(\.userID == user.id).filter(\.id == id).first().unwrap(or: Abort(.notFound))
        return order.flatMap { try $0.response(on: request) }
    }
}
