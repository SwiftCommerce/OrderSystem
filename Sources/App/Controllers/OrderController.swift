import JWTMiddleware
import Fluent
import Vapor

final class OrderController: RouteCollection {
    func boot(router: Router) throws {
        let orders = router.grouped("orders")
        let protected = orders.grouped(JWTStorageMiddleware<User>())
        
        orders.post(OrderContent.self, use: create)
        protected.get(use: all)
        protected.get(Order.parameter, use: get)
        
        protected.post(ItemContent.self, at: Order.parameter, "items", use: addItem)
        protected.delete(Order.parameter, "items", Item.ID.parameter, use: removeItem)
    }
    
    func create(_ request: Request, content: OrderContent)throws -> Future<Order.Response> {
        let order = Order()
        content.populate(order: order)
        
        let user: User?
        let email: String
        
        if let token = request.http.headers.bearerAuthorization?.token {
            let data = Data(token.utf8)
            let jwt = try JWT<User>(unverifiedFrom: data)
            user = jwt.payload
        } else {
            let configuration = try request.make(OrderService.self)
            guard configuration.guestCheckout else {
                throw Abort(.unauthorized, reason: "Authorization required to create an order")
            }
            user = nil
        }
        
        if let userEmail = user?.email {
            email = userEmail
        } else {
            let prefix = order.guest ? "guest" : "user"
            email = prefix + UUID().uuidString + "@ordersystem.example.com"
        }
        
        order.userID = user?.id
        order.email = email
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
        guard let user = try request.get(payload, as: User.self), let id = user.id else {
            throw Abort(.unauthorized, reason: "You must be logged into your account to view past orders.")
        }
        return try Order.query(on: request).filter(\.userID == id).all().response(on: request)
    }
    
    
    func get(_ request: Request)throws -> Future<Order.Response> {
        guard
            let user = try request.get(payload, as: User.self),
            let rawID = request.parameters.rawValues(for: Order.self).first,
            let id = Int(rawID),
            user.id != nil
        else {
            throw Abort(.notFound)
        }

        let order = Order.query(on: request).filter(\.userID == user.id).filter(\.id == id).first().unwrap(or: Abort(.notFound))
        return order.flatMap { try $0.response(on: request) }
    }
    
    func addItem(_ request: Request, content: ItemContent)throws -> Future<Order.Response> {
        return try request.parameters.next(Order.self).flatMap { order in
            let newItem = try content.save(on: request, order: order.requireID())
            return newItem.flatMap { _ in try order.response(on: request) }
        }
    }
    
    func removeItem(_ request: Request)throws -> Future<HTTPStatus> {
        let payload = try request.get(.payloadKey, as: User.self)
        
        
        return try request.parameters.next(Order.self).flatMap { order in
            let itemID = try request.parameters.next(Item.ID.self)
            let deletedItem = try Item.query(on: request).filter(\.orderID == order.requireID()).filter(\.id == itemID).delete()
            return deletedItem.transform(to: .noContent)
        }
    }
}
