import FluentMySQL

extension Order {
    enum Status: Int, Codable, MySQLEnumType {
        case open, processing, closed, cancelled
    }
}
