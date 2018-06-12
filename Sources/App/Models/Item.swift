import Foundation
import FluentMySQL
import Vapor

final class Item: Content, MySQLModel, Migration {
    var id: Int?

    let orderID: Int
    let sku: String
    var price: Int
    var quantity: Int
    
    var tax: Int { print("TODO: Set `Item.tax` property the correct way"); return Int((Double(self.total) * 0.8)) }
    var total: Int { return price * quantity }
    var totalWithTax: Int { return total + tax }
    
    init(orderID: Int, sku: String, price: Int, quantity: Int) {
        self.orderID = orderID
        self.sku = sku
        self.price = price
        self.quantity = quantity
    }
    
    public static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            try builder.addReference(from: \.orderID, to: \Order.id)
        }
    }
}



extension Item {
    struct Response: Content {
        let orderID, price, quantity, tax, total, totalWithTax: Int
        let sku: String
    }
    struct OrderResponse: Content {
        let price, quantity, tax, total, totalWithTax: Int
        let sku: String
    }
    var orderResponse: OrderResponse {
        return OrderResponse(price: self.price, quantity: self.quantity, tax: self.tax, total: self.total, totalWithTax: self.totalWithTax, sku: self.sku)
    }
    
    var response: Response {
        return Response(orderID: self.orderID, price: self.price, quantity: self.quantity, tax: self.tax, total: self.total, totalWithTax: self.totalWithTax, sku: self.sku)
    }
}
