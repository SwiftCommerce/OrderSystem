import FluentMySQL

final class OrderAddress {
    var id: Int?
    let address: Address.ID
    let order: Order.ID
    let purpose: Purpose
    
    init(address: Address.ID, order: Order.ID, purpose: Purpose = .shipping) {
        self.address = address
        self.order = order
        self.purpose = purpose
    }
    
    enum Purpose: String, Codable, CaseIterable, MySQLEnumType {
        case billing
        case shipping
        
        static var mysqlDataType: MySQLDataType {
            return .enum(Purpose.allCases.map { $0.rawValue })
        }
    }
}

extension OrderAddress: Migration {
    static func prepare(on conn: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: conn) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.order, to: \Order.id)
        }
    }
}

extension OrderAddress: MySQLModel { }
