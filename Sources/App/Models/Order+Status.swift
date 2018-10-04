import FluentMySQL

extension Order {
    enum Status: Int, Codable, Equatable, MySQLEnumType {
        static func reflectDecoded() throws -> (Order.Status, Order.Status) {
            return (.open, .cancelled)
        }
        
        case open, processing, closed, cancelled
    }
}
