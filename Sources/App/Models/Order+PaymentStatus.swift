import FluentMySQL

extension Order {
    enum PaymentStatus: Int {
        case open, partial, paid, refunded
    }
}

extension Order.PaymentStatus: MySQLDataConvertible, MySQLColumnDefinitionStaticRepresentable {
    static var mySQLColumnDefinition: MySQLColumnDefinition = .tinyInt()
    
    func convertToMySQLData() throws -> MySQLData {
        return .init(integer: self.rawValue)
    }
    
    static func convertFromMySQLData(_ mysqlData: MySQLData) throws -> Order.PaymentStatus {
        guard let rawValue = try mysqlData.integer(Int.self) else {
            throw FluentError(identifier: "badDataType", reason: "Cannot create `Order.PaymentStatus` instance from non-`Int` type", source: .capture())
        }
        guard let instance = Order.PaymentStatus(rawValue: rawValue) else {
            throw FluentError(identifier: "badRawValue", reason: "Cannot create `Order.PaymentStatus` from value '\(rawValue)'", source: .capture())
        }
        return instance
    }
}
