import FluentMySQL
import Vapor

final class AccountSetting: Content, MySQLModel, Migration, Parameter {
    var id: Int?
    
    let accountID: Account.ID
    let name: String
    var value: String
    
    init(account: Account.ID, name: String, value: String) {
        self.accountID = account
        self.name = name
        self.value = value
    }
    
    public static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            try builder.addReference(from: \.accountID, to: \Account.id)
        }
    }
}
