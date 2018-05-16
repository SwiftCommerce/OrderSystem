import Foundation
import FluentMySQL
import Vapor

final class Item: Codable, Content, MySQLModel, Migration {
    var id: Int?

    let orderID: Int
    let sku: String
    var price: Int
    var quantity: Int
    
    var tax: Int { print("TODO: Set `Item.tax` property the correct way"); return Int((Double(self.total) * 0.08)) }
    var total: Int { return price * quantity }
    var totalWithTax: Int { return total + tax }
    
    init(from decoder: Decoder)throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
        self.orderID = try container.decode(Int.self, forKey: .orderID)
        self.sku = try container.decode(String.self, forKey: .sku)
        self.price = try container.decode(Int.self, forKey: .price)
        self.quantity = try container.decode(Int.self, forKey: .quantity)
    }
}

extension Item {
    struct Response: Content {
        let orderID, price, quantity, tax, total, totalWithTax: Int
        let sku: String
    }
    
    var response: Response {
        return Response(orderID: self.orderID, price: self.price, quantity: self.quantity, tax: self.tax, total: self.total, totalWithTax: self.totalWithTax, sku: self.sku)
    }
}
