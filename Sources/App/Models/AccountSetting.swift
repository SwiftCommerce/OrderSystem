import FluentMySQL
import Vapor

final class AccountSetting: Content, MySQLModel, Migration {
    var id: Int?
    
    let accountID: Account.ID
    let name: String
    var value: String
}
