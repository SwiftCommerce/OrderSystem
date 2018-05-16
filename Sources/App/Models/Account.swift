import FluentMySQL
import Vapor

final class Account: Content, MySQLModel, Migration, Parameter {
    var id: Int?
}
