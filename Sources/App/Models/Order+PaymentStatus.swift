import FluentMySQL

extension Order {
    enum PaymentStatus: Int, Codable, MySQLEnumType {
        case open, partial, paid, refunded, failure
    }
}
