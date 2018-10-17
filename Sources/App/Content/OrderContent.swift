import Vapor

/// A JSON representation of an `Order` model.
///
/// This type is decoded from the request body in the `OrderController.create` route handler
/// to create the `Order` model instance that will be saved.
struct OrderContent: Content {
    var currency: String
    var accountID: Int?
    var comment: String?
    var firstname: String?
    var lastname: String?
    var company: String?
    var email: String?
    var phone: String?
    var addresses: OrderAddress?
    var items: [ItemContent]?
    
    func populate(order: Order) {
        order.currency = self.currency
        order.accountID = self.accountID
        order.comment = self.comment
        order.firstname = self.firstname
        order.lastname = self.lastname
        order.company = self.company
        order.email = self.email
        order.phone = self.phone
    }
}
