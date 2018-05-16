import FluentMySQL
import Vapor

final class AccountSetting: Content, MySQLModel, Migration {
    var id: Int?
    
    let accountID: Account.ID
    let name: String
    var value: String
    
    init(from decoder: Decoder)throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
        self.accountID = try container.decode(Account.ID.self, forKey: .accountID)
        self.name = try container.decode(String.self, forKey: .name)
        self.value = try container.decode(String.self, forKey: .value)
    }
    
    public static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            try builder.addReference(from: \.accountID, to: \Account.id)
        }
    }
}
