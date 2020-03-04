import FluentMySQL
import Vapor

final class Account: Content, MySQLModel, Migration, Parameter {
    typealias Database = MySQLDatabase

    var id: Int?
    let userID: User.ID
    
    init(userID: User.ID) {
        self.userID = userID
    }
}
