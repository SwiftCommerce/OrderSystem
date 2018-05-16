import FluentMySQL

final class OrderItem: MySQLPivot, Migration {
    typealias Left = Order
    typealias Right = Item
    
    static var leftIDKey: WritableKeyPath<OrderItem, Int> = \.orderID
    static var rightIDKey: WritableKeyPath<OrderItem, Int> = \.itemID
    
    var id: Int?
    var orderID: Order.ID
    var itemID: Item.ID
    
    init(order: Order, item: Item)throws {
        self.orderID = try order.requireID()
        self.itemID = try item.requireID()
    }
    
    public static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            try builder.addReference(from: \.orderID, to: \Order.id)
            try builder.addReference(from: \.itemID, to: \Item.id)
        }
    }
}
