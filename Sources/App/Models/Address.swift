import FluentMySQL
import Vapor

final class Address {
    var id: Int?
    
    var street: String?
    var street2: String?
    var zip: String?
    var city: String?
    var state: String?
    var country: String?
    var shipping: Bool
    
    var orderID: Order.ID
    
    init(order: Order.ID, street: String?, street2: String?, zip: String?, city: String?, state: String?, country: String?, shipping: Bool) {
        self.street = street
        self.street2 = street2
        self.zip = zip
        self.city = city
        self.state = state
        self.country = country
        self.shipping = shipping
        self.orderID = order
    }
}

extension Address: Content {}
extension Address: Parameter {}
extension Address: Migration {}
extension Address: MySQLModel {}

extension Address {
    struct Response: Content {
        var street, street2, zip, city, state, country: String?
        
        init(address: Address) {
            self.street = address.street
            self.street2 = address.street2
            self.zip = address.zip
            self.city = address.city
            self.state = address.state
            self.country = address.country
        }
    }
    
    var response: Response {
        return Response(address: self)
    }
}
