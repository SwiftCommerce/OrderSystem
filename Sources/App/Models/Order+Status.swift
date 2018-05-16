import FluentMySQL

extension Order {
    enum Status: Int {
        case open, processing, closed, cancelled
    }
}

extension Order.Status: MySQLDataConvertible, MySQLColumnDefinitionStaticRepresentable {
    static var mySQLColumnDefinition: MySQLColumnDefinition { return .tinyInt() }
    
    func convertToMySQLData() throws -> MySQLData {
        return .init(integer: self.rawValue)
    }
    
    static func convertFromMySQLData(_ mysqlData: MySQLData) throws -> Order.Status {
        guard let rawValue = try mysqlData.integer(Int.self) else {
            throw FluentError(identifier: "badDataType", reason: "Connot create `Order.Status` instance from non-`Int` type", source: .capture())
        }
        guard let instance = Order.Status(rawValue: rawValue) else {
            throw FluentError(identifier: "badRawValue", reason: "Coannot create `Order.Status` from value '\(rawValue)'", source: .capture() )
        }
        return instance
    }
}
