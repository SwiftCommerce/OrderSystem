import FluentMySQL

extension Order {
    enum Status: Int {
        case open, processing, closed, cancelled
    }
}
