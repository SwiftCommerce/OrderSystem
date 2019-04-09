import FluentMySQL

extension Order {
    enum PaymentStatus: Int, Codable, Hashable, CaseIterable, MySQLEnumType {
        case open, partial, paid, refunded, failure
    }
}
