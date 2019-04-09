import FluentMySQL

extension Order {
    enum Status: Int, Codable, Hashable, CaseIterable, MySQLEnumType {
        case open, processing, closed, cancelled
    }
}
