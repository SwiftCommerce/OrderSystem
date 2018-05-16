import Fluent
import Vapor

final class AccountSettingController: RouteCollection {
    func boot(router: Router) throws {
        let settings = router.grouped(any, "account", Account.parameter, "settings")
        
        settings.post(AccountSettingContent.self, use: create)
        settings.get(use: all)
        settings.get(AccountSetting.parameter, use: get)
        settings.patch(AccountSetting.parameter, use: update)
        settings.delete(AccountSetting.parameter, use: delete)
    }
    
    func create(_ request: Request, _ setting: AccountSettingContent)throws -> Future<AccountSetting> {
        let accountID = try request.parameters.next(Account.ID.self)
        return AccountSetting(account: accountID, name: setting.name, value: setting.value).save(on: request)
    }
    
    func all(_ request: Request)throws -> Future<[AccountSetting]> {
        let accountID = try request.parameters.next(Account.ID.self)
        return try AccountSetting.query(on: request).filter(\.accountID == accountID).all()
    }
    
    func get(_ request: Request)throws -> Future<AccountSetting> {
        let accountID = try request.parameters.next(Account.ID.self)
        let settingID = try request.parameters.next(AccountSetting.ID.self)
        
        return try Account.query(on: request).filter(\.id == accountID).count().flatMap(to: AccountSetting?.self) { count in
            guard count > 0 else {
                throw Abort(.notFound, reason: "No account found with ID '\(accountID)'")
            }
            return try AccountSetting.query(on: request).filter(\.accountID == accountID).filter(\.id == settingID).first()
        }.unwrap(or: Abort(.notFound, reason: "No account setting found with ID '\(settingID)' for account '\(accountID)'"))
    }
    
    func update(_ request: Request)throws -> Future<AccountSetting> {
        let accountID = try request.parameters.next(Account.ID.self)
        let settingID = try request.parameters.next(AccountSetting.ID.self)
        let value = try request.content.syncGet(String.self, at: "value")
        
        return try Account.query(on: request).filter(\.id == accountID).count().flatMap(to: AccountSetting?.self) { count in
            guard count > 0 else {
                throw Abort(.notFound, reason: "No account found with ID '\(accountID)'")
            }
            return try AccountSetting.query(on: request).filter(\.accountID == accountID).filter(\.id == settingID).first()
        }
        .unwrap(or: Abort(.notFound, reason: "No account setting found with ID '\(settingID)' for account '\(accountID)'"))
        .flatMap(to: AccountSetting.self) { setting in
            setting.value = value
            return setting.update(on: request)
        }
    }
    
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        let accountID = try request.parameters.next(Account.ID.self)
        let settingID = try request.parameters.next(AccountSetting.ID.self)
        
        return try Account.query(on: request).filter(\.id == accountID).count().flatMap(to: HTTPStatus.self) { count in
            guard count > 0 else {
                throw Abort(.notFound, reason: "No account found with ID '\(accountID)'")
            }
            return try AccountSetting.query(on: request).filter(\.accountID == accountID).filter(\.id == settingID).delete().transform(to: .noContent)
        }
    }
}

struct AccountSettingContent: Content {
    let id: AccountSetting.ID?
    let accountID: Account.ID?
    let name: String
    let value: String
}
