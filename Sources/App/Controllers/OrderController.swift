import JWTMiddleware
import Fluent
import Vapor

final class OrderController: RouteCollection {
    func boot(router: Router) throws {
        let orderRoute = router.grouped(JWTVerificationMiddleware()).grouped("orders")
        
        orderRoute.post(OrderContent.self, use: create)
        orderRoute.get(use: all)
        orderRoute.get(AccountSetting.parameter, use: get)
        orderRoute.patch(AccountSetting.parameter, use: update)
        orderRoute.delete(AccountSetting.parameter, use: delete)
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
            let addresses = content.addresses?.save(on: request) ?? request.future()
            
            return items.and(addresses).transform(to: order)
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

struct OrderContent: Content {
    var accountID: Int?
    var comment: String?
    var firstname: String?
    var lastname: String?
    var company: String?
    var email: String?
    var phone: String?
    var addresses: OrderAddress?
    var items: [ItemContent]?
    
    func populate(order: Order) {
        order.accountID = self.accountID
        order.comment = self.comment
        order.firstname = self.firstname
        order.lastname = self.lastname
        order.company = self.company
        order.email = self.email
        order.phone = self.phone
    }
}

struct ItemContent: Content {
    let sku: String
    let name: String
    let description: String?
    var price: Int
    var quantity: Int
    
    func save(on conn: DatabaseConnectable, order: Order.ID) -> Future<Item> {
        let item = Item(
            orderID: order,
            sku: self.sku,
            name: self.name,
            description: self.description,
            price: self.price,
            quantity: self.quantity
        )
        return item.save(on: conn)
    }
}

struct OrderAddress: Content {
    let shipping: Address?
    let billing: Address?
    
    func save(on conn: DatabaseConnectable) -> Future<Void> {
        self.shipping?.shipping = true
        self.billing?.shipping = false
        
        let shipping = self.shipping?.save(on: conn).transform(to: ()) ?? conn.future()
        let billing = self.billing?.save(on: conn).transform(to: ()) ?? conn.future()
        return map(shipping, billing) { _, _ in return () }
    }
}
