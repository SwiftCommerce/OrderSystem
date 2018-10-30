import Vapor

struct Product: Content {
    let id: Int?
    let sku: String
    let name: String
    let description: String?
    let price: Price?
}

struct Price: Content {
    var id: Int?
    var cents: Int
    var currency: String
}
