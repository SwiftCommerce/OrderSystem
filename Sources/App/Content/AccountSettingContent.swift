import Vapor

struct AccountSettingContent: Content {
    let id: AccountSetting.ID?
    let accountID: Account.ID?
    let name: String
    let value: String
}
