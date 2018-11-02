import Vapor

struct Product: Content {
    let id: Int?
    let sku: String
    let name: String
    let description: String?
    let price: Price?
}

struct Price: Content {
    let id: Int?
    let cents: Int
    let active: Bool
    let currency: String
}
