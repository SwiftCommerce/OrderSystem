import FluentMySQL
import Vapor

final class Item: Content, MySQLModel, Migration {
    var id: Int?
}
