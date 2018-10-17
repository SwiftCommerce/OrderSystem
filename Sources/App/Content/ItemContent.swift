import Vapor

/// A JSON representation of an `Item` model.
///
/// This type is used to create the `Item` models connected
/// to the `Order` model created in the `OrderController.create` handler.
struct ItemContent: Content {
    let sku: String
    let name: String
    let description: String?
    var price: Int
    var quantity: Int
    
    func save(on conn: DatabaseConnectable, order: Order.ID) -> Future<Item> {
        let item = Item(
            orderID: order,
            sku: self.sku,
            name: self.name,
            description: self.description,
            price: self.price,
            quantity: self.quantity
        )
        return item.save(on: conn)
    }
}
