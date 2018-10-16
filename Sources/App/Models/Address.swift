import FluentMySQL
import Vapor

final class Address {
    var id: Int?
    
    var street: String?
    var street2: String?
    var zip: String?
    var city: String?
    var country: String?
    var shipping: Bool
    
    var orderID: Order.ID
    
    init(order: Order.ID, street: String?, street2: String?, zip: String?, city: String?, country: String?, shipping: Bool) {
        self.street = street
        self.street2 = street2
        self.zip = zip
        self.city = city
        self.country = country
        self.shipping = shipping
        self.orderID = order
    }
}

extension Address: Content {}
extension Address: Parameter {}
extension Address: Migration {}
extension Address: MySQLModel {}
