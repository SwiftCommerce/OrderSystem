import Foundation
import FluentMySQL
import Vapor

final class Item: Content, MySQLModel, Migration {
    typealias ProductID = Int
    
    var id: Int?

    let orderID: Int
    let productID: ProductID
    let taxCode: String?
    
    var quantity: Int
    
    init(orderID: Int, productID: ProductID, quantity: Int, taxCode: String?) {
        self.orderID = orderID
        self.productID = productID
        self.taxCode = taxCode
        self.quantity = quantity
    }
    
    func total(for price: Int) -> Int { return price * quantity }
    
    public static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.orderID, to: \Order.id)
        }
    }
}



extension Item {
    struct Response: Content {
        let orderID, quantity: Int
        let productID: ProductID
        let taxCode: String?
    }
    struct OrderResponse: Content {
        let quantity: Int
        let productID: ProductID
        let taxCode: String?
    }
    
    var response: Response {
        return Response(orderID: self.orderID, quantity: self.quantity, productID: self.productID, taxCode: self.taxCode)
    }
    var orderResponse: OrderResponse {
        return OrderResponse(quantity: self.quantity, productID: self.productID, taxCode: self.taxCode)
    }
}
