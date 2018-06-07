import JWTMiddleware
import Fluent
import Vapor

final class OrderController: RouteCollection {
    func boot(router: Router) throws {
        let orderRoute = router.grouped(JWTVerificationMiddleware()).grouped("orders")
        
        orderRoute.post(NewOrder.self, use: create)
        orderRoute.get(use: all)
        orderRoute.get(AccountSetting.parameter, use: get)
        orderRoute.patch(AccountSetting.parameter, use: update)
        orderRoute.delete(AccountSetting.parameter, use: delete)
    }
    
    func create(_ request: Request, _ orderParameters: NewOrder)throws -> Future<Order.Response> {
        //let accountID = try request.parameters.next(Account.ID.self)
        
        let order = Order()
        
        
        return order.save(on: request).flatMap(to: Order.Response.self) { order in
            return try order.response(on: request)
        }
    }
    
    func all(_ request: Request)throws -> Future<[AccountSetting]> {
        let accountID = try request.parameters.next(Account.ID.self)
        return try AccountSetting.query(on: request).filter(\.accountID == accountID).all()
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
    
    func settings<T>(from request: Request, finishing: @escaping (QueryBuilder<AccountSetting, AccountSetting>, Account.ID, AccountSetting.ID) -> Future<T>) -> Future<T> {
        return Future.flatMap(on: request) {
            let accountID = try request.parameters.next(Account.ID.self)
            let settingID = try request.parameters.next(AccountSetting.ID.self)
            
            return try Account.query(on: request).filter(\.id == accountID).count().flatMap(to: T.self) { count in
                guard count > 0 else {
                    throw Abort(.notFound, reason: "No account found with ID '\(accountID)'")
                }
                let query = try AccountSetting.query(on: request).filter(\.accountID == accountID).filter(\.id == settingID)
                return finishing(query, accountID, settingID)
            }
        }
    }
}

struct NewOrder: Content {
    let accountID: Account.ID?
}
