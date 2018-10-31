import Foundation
import FluentMySQL
import Vapor

final class Item: Content, MySQLModel, Migration {
    typealias ProductID = Int
    
    var id: Int?

    let orderID: Int
    let productID: ProductID
    let taxRate: Decimal
    
    var quantity: Int
    
    init(orderID: Int, productID: ProductID, quantity: Int, taxRate: Decimal) {
        self.orderID = orderID
        self.productID = productID
        self.taxRate = taxRate
        self.quantity = quantity
    }
    
    func total(for price: Int) -> Int { return price * quantity }
    func tax(for price: Int) -> Int { return NSDecimalNumber(decimal: Decimal(self.total(for: price)) * (taxRate / 100)).intValue }
    
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
        let taxRate: Decimal
    }
    struct OrderResponse: Content {
        let quantity: Int
        let productID: ProductID
        let taxRate: Decimal
    }
    
    var response: Response {
        return Response(orderID: self.orderID, quantity: self.quantity, productID: self.productID, taxRate: self.taxRate)
    }
    var orderResponse: OrderResponse {
        return OrderResponse(quantity: self.quantity, productID: self.productID, taxRate: self.taxRate)
    }
}
