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

extension Address {
    struct Response: Content {
        var street, street2, zip, city, country: String?
        var shipping: Bool
        
        init(address: Address) {
            self.street = address.street
            self.street2 = address.street2
            self.zip = address.zip
            self.city = address.city
            self.country = address.country
            self.shipping = address.shipping
        }
    }
    
    var response: Response {
        return Response(address: self)
    }
}
