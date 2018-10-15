import JWTMiddleware
import Fluent
import Vapor

final class OrderController: RouteCollection {
    func boot(router: Router) throws {
        let orderRoute = router.grouped(JWTVerificationMiddleware()).grouped("orders")
        
        orderRoute.post(Order.self, use: create)
        orderRoute.get(use: all)
        orderRoute.get(AccountSetting.parameter, use: get)
        orderRoute.patch(AccountSetting.parameter, use: update)
        orderRoute.delete(AccountSetting.parameter, use: delete)
    }
    
    func create(_ request: Request, _ order: Order)throws -> Future<Order.Response> {
        guard order.accountID != nil else {
            throw Abort(.badRequest, reason: "No account id given.")
        }
        
        let user: User? = try request.get("skelpo-payload")
        order.userID = user?.id
        
        let items = request.content.get([ItemContent]?.self, at: "items").map { $0 ?? [] }
        let saved = order.save(on: request)

        
        return flatMap(saved, items) { order, itemsData -> Future<Order> in
            let id = try order.requireID()
            let items = itemsData.map { data -> Future<Item> in
                let item = Item(
                    orderID: id,
                    sku: data.sku,
                    name: data.name,
                    description: data.description,
                    price: data.price,
                    quantity: data.quantity
                )
                return item.save(on: request)
            }.flatten(on: request)
            
            return items.transform(to: order)
        }.flatMap { order in
            return try order.response(on: request)
        }
    }
    
    func all(_ request: Request)throws -> Future<[Order.Response]> {
        let user:User = try request.get("skelpo-payload")!
        return try Order.query(on: request).filter(\.userID == user.id).all().response(on: request)
    }
    
    
    func get(_ request: Request)throws -> Future<AccountSetting> {
        return self.settings(from: request) { query, account, setting in
            return query.first().unwrap(or: Abort(.notFound, reason: "No account setting found with ID '\(setting)' for account '\(account)'"))
        }
    }
    
    func update(_ request: Request)throws -> Future<AccountSetting> {
        let value = try request.content.syncGet(String.self, at: "value")
        
        return self.settings(from: request) { query, account, setting in
            return query.first().unwrap(or: Abort(.notFound, reason: "No account setting found with ID '\(setting)' for account '\(account)'"))
            }.flatMap(to: AccountSetting.self) { setting in
                setting.value = value
                return setting.update(on: request)
        }
    }
    
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        return self.settings(from: request) { query, _, _ in query.delete().transform(to: .noContent) }
    }
    
    func settings<T>(
        from request: Request,
        finishing: @escaping (QueryBuilder<AccountSetting.Database, AccountSetting>, Account.ID, AccountSetting.ID
    ) -> Future<T>) -> Future<T> {
        return Future.flatMap(on: request) {
            let accountID = try request.parameters.next(Account.ID.self)
            let settingID = try request.parameters.next(AccountSetting.ID.self)
            
            return Account.query(on: request).filter(\.id == accountID).count().flatMap(to: T.self) { count in
                guard count > 0 else {
                    throw Abort(.notFound, reason: "No account found with ID '\(accountID)'")
                }
                let query = AccountSetting.query(on: request).filter(\.accountID == accountID).filter(\.id == settingID)
                return finishing(query, accountID, settingID)
            }
        }
    }
}

struct ItemContent: Content {
    let sku: String
    let name: String
    let description: String?
    var price: Int
    var quantity: Int
}
