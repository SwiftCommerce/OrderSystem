import FluentMySQL
import Vapor

final class Order: Content, MySQLModel, Migration {
    var id: Int?
}
