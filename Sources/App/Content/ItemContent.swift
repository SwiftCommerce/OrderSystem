import Vapor

/// A JSON representation of an `Item` model.
///
/// This type is used to create the `Item` models connected
/// to the `Order` model created in the `OrderController.create` handler.
struct ItemContent: Content {
    let productID: Item.ProductID
    let quantity: Int
    let taxRate: Decimal
    
    func save(on conn: DatabaseConnectable, order: Order.ID) -> Future<Item> {
        let item = Item(
            orderID: order,
            productID: self.productID,
            quantity: self.quantity,
            taxRate: self.taxRate
        )
        return item.save(on: conn)
    }
}
