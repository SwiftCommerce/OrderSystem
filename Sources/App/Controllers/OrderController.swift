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
        protected.patch(OrderContent.self, at: Order.parameter, use: update)
        
        protected.post(ItemContent.self, at: Order.parameter, "items", use: addItem)
        protected.delete(Order.parameter, "items", Item.ID.parameter, use: removeItem)
    }
    
    func create(_ request: Request, content: OrderContent)throws -> Future<Order.Result> {
        let order = Order()
        content.populate(order: order)
        
        let user: User?
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
        
        order.userID = user?.id
        order.email = user?.email
        let saved = order.save(on: request)

        return saved.flatMap { order -> Future<Order> in
            let id = try order.requireID()
            let items = (content.items ?? []).map { data in data.save(on: request, order: id) }.flatten(on: request)
            let addresses = content.addresses?.save(on: request, order: id) ?? request.future()
            
            return items.and(addresses).transform(to: order)
        }.response(on: request)
    }
    
    func all(_ request: Request)throws -> Future<[Order.Result]> {
        guard let user = try request.get(.payloadKey, as: User.self), let id = user.id else {
            throw Abort(.unauthorized, reason: "You must be logged into your account to view past orders.")
        }
        return Order.query(on: request).filter(\.userID == id).all().response(on: request)
    }
    
    
    func get(_ request: Request)throws -> Future<Order.Result> {
        guard
            let user = try request.get(.payloadKey, as: User.self),
            let rawID = request.parameters.rawValues(for: Order.self).first,
            let id = Int(rawID),
            user.id != nil
        else {
            throw Abort(.notFound)
        }

        let order = Order.query(on: request).filter(\.userID == user.id).filter(\.id == id).first().unwrap(or: Abort(.notFound))
        return order.response(on: request)
    }
    
    func update(_ request: Request, content: OrderContent)throws -> Future<Order.Result> {
        return self.order(for: request).map{ order -> Order in
            content.populate(order: order)
            return order
        }.save(on: request).response(on: request)
    }
    
    func addItem(_ request: Request, content: ItemContent)throws -> Future<Order.Result> {
        return self.order(for: request).flatMap { order in
            let newItem = try content.save(on: request, order: order.requireID())
            return newItem.flatMap { _ in order.response(on: request) }
        }
    }
    
    func removeItem(_ request: Request)throws -> Future<HTTPStatus> {
        return self.order(for: request).flatMap { order in
            let itemID = try request.parameters.next(Item.ID.self)
            let deletedItem = try Item.query(on: request).filter(\.orderID == order.requireID()).filter(\.id == itemID).delete()
            return deletedItem.transform(to: .noContent)
        }
    }
}

extension OrderController {
    func order(for request: Request) -> Future<Order> {
        do {
            let payload = try request.get(.payloadKey, as: User.self)
            
            if let status = payload?.status, status == .admin {
                return try request.parameters.next(Order.self)
            } else if let user = payload?.id, let raw = request.parameters.rawValues(for: Order.self).first, let id = Order.ID(raw) {
                return Order.query(on: request).filter(\.userID == user).filter(\.id == id).first().unwrap(or: Abort(.notFound))
            } else {
                throw Abort(.notFound)
            }
        } catch let error {
            return request.future(error: error)
        }
    }
}
