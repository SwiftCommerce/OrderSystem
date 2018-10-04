import FluentMySQL

extension Order {
    enum PaymentStatus: Int, Codable, Equatable, MySQLEnumType {
        static func reflectDecoded() throws -> (Order.PaymentStatus, Order.PaymentStatus) {
            return (.open, .failure)
        }
        
        case open, partial, paid, refunded, failure
    }
}
