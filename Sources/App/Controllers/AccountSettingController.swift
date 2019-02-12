import JWTMiddleware
import Fluent
import Vapor

final class AccountSettingController: RouteCollection {
    func boot(router: Router) throws {
        let settings = router.grouped(JWTStorageMiddleware<User>()).grouped("orders", "account", Account.ID.parameter, "settings")
        
        settings.post(AccountSettingContent.self, use: create)
        settings.get(use: all)
        settings.get(AccountSetting.ID.parameter, use: get)
        settings.patch(AccountSetting.ID.parameter, use: update)
        settings.delete(AccountSetting.ID.parameter, use: delete)
    }
    
    func create(_ request: Request, _ setting: AccountSettingContent)throws -> Future<AccountSetting> {
        let accountID = try request.parameters.next(Account.ID.self)
        return AccountSetting(account: accountID, name: setting.name, value: setting.value).save(on: request)
    }
    
    func all(_ request: Request)throws -> Future<[AccountSetting]> {
        let accountID = try request.parameters.next(Account.ID.self)
        return AccountSetting.query(on: request).filter(\.accountID == accountID).all()
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
        finishing: @escaping (QueryBuilder<AccountSetting.Database, AccountSetting>, Account.ID, AccountSetting.ID) -> Future<T>
    ) -> Future<T> {
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
