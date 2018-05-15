import Foundation
import FluentMySQL
import Vapor

final class Item: Codable, Content, MySQLModel, Migration {
    var id: Int?

    let orderID: Int
    let sku: String
    var price: Int
    var quantity: Int
    
    var tax: Int { print("TODO: Set `Item.tax` property the correct way"); return 108 }
    var total: Int { return price * quantity }
    var totalWithTax: Int { return (total * tax) / 100 }
    
    init(from decoder: Decoder)throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
        self.orderID = try container.decode(Int.self, forKey: .orderID)
        self.sku = try container.decode(String.self, forKey: .sku)
        self.price = try container.decode(Int.self, forKey: .price)
        self.quantity = try container.decode(Int.self, forKey: .quantity)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, orderID, sku, price, quantity
    }
}
