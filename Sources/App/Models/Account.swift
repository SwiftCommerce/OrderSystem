import FluentMySQL
import Vapor

final class Account: Content, MySQLModel, Migration {
    var id: Int?
}
