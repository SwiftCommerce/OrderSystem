import Vapor

/// A JSON representation of the `Address` model.
///
/// This is the address structure for the `Address` models that will
/// be connected to the `Order` model created in the `OrderController.create` route handler.
struct AddressContent: Content {
    var street: String?
    var street2: String?
    var zip: String?
    var city: String?
    var country: String?
    
    func save(on conn: DatabaseConnectable, order: Order.ID, isShipping: Bool) -> Future<Address> {
        let address = Address(
            order: order,
            street: self.street,
            street2: self.street2,
            zip: self.zip,
            city: self.city,
            country: self.country,
            shipping: isShipping
        )
        return address.save(on: conn)
    }
}

/// Wraps the address content data, so they `shipping` and `billing` addresses are keyed for the client.
struct OrderAddress: Content {
    let shipping: AddressContent?
    let billing: AddressContent?
    
    func save(on conn: DatabaseConnectable, order: Order.ID) -> Future<Void> {
        let shipping = self.shipping?.save(on: conn, order: order, isShipping: true).transform(to: ()) ?? conn.future()
        let billing = self.billing?.save(on: conn, order: order, isShipping: false).transform(to: ()) ?? conn.future()
        return [shipping, billing].flatten(on: conn)
    }
}
