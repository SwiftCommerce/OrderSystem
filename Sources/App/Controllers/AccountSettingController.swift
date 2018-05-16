import Fluent
import Vapor

final class AccountSettingController: RouteCollection {
    func boot(router: Router) throws {}
    
    func create(_ request: Request, _ setting: AccountSettingContent)throws -> Future<AccountSetting> {
        let accountID = try request.parameters.next(Account.ID.self)
        return AccountSetting(account: accountID, name: setting.name, value: setting.value).save(on: request)
    }
    
    func all(_ request: Request)throws -> Future<[AccountSetting]> {
        let accountID = try request.parameters.next(Account.ID.self)
        return try AccountSetting.query(on: request).filter(\.accountID == accountID).all()
    }
}

struct AccountSettingContent: Content {
    let id: AccountSetting.ID?
    let accountID: Account.ID?
    let name: String
    let value: String
}
