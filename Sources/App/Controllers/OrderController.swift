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
        let order = Order()
        
        guard let accountID = orderParameters.accountID else {
            throw Abort(.badRequest, reason: "No account id given.")
        }
        
        guard let items = orderParameters.items else {
            throw Abort(.badRequest, reason: "We don't like empty orders.")
        }
        
        let user:User = try request.get("skelpo-payload")!
        order.userID = user.id
        order.accountID = accountID

        order.firstname = orderParameters.firstname
        order.lastname = orderParameters.lastname
        order.email = orderParameters.email
        order.street = orderParameters.street
        order.city = orderParameters.city
        order.zip = orderParameters.zip
        order.country = orderParameters.country
        order.phone = orderParameters.phone
        order.company = orderParameters.company
        
        
        return order.save(on: request).flatMap(to: Order.Response.self) { order in
            var savingItems:[Future<Item>] = []
            for item in items {
                let i = Item(orderID: order.id!, sku: item.sku, price: item.price, quantity: item.quantity).save(on: request)
                savingItems.append(i)
            }
            return savingItems.flatten(on: request).flatMap(to: Order.Response.self) { items in
                return try order.response(on: request)
            }
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

struct NewItem: Content {
    let sku: String
    var price: Int
    var quantity: Int
}

struct NewOrder: Content {
    let accountID: Account.ID?
    let items:[NewItem]?
    let firstname:String?
    let lastname:String?
    let email:String?
    let street:String?
    let city:String?
    let zip:String?
    let country:String?
    let company:String?
    let phone:String?
}
