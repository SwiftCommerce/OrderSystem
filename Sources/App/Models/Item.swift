import Foundation
import FluentMySQL
import Vapor

final class Item: Content, MySQLModel, Migration {
    typealias Database = MySQLDatabase
    typealias ProductID = Int
    
    var id: Int?

    let orderID: Int
    let productID: ProductID
    let taxCode: String?
    
    var quantity: Int
    var paidTotal: Int?
    
    init(orderID: Int, productID: ProductID, quantity: Int, taxCode: String?) {
        self.orderID = orderID
        self.productID = productID
        self.taxCode = taxCode
        self.quantity = quantity
        self.paidTotal = nil
    }
    
    func total(for price: Int) -> Int { return price * quantity }
    
    func saveTotal(from product: Product, for currency: String, on conn: DatabaseConnectable) -> Future<Item> {
        if let price = product.currenctPrice(for: currency) {
            self.paidTotal = price.cents
            return self.update(on: conn)
        } else {
            return conn.future(self)
        }
    }
    
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
        let paid: Int?
    }
    struct OrderResponse: Content {
        let quantity: Int
        let productID: ProductID
        let taxCode: String?
        let paid: Int?
    }
    
    var response: Response {
        return Response(orderID: self.orderID, quantity: self.quantity, productID: self.productID, taxCode: self.taxCode, paid: self.paidTotal)
    }
    var orderResponse: OrderResponse {
        return OrderResponse(quantity: self.quantity, productID: self.productID, taxCode: self.taxCode, paid: self.paidTotal)
    }
}
