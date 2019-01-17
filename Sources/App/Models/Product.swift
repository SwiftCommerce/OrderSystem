import Vapor

struct Product: Content {
    let id: Int?
    let sku: String
    let name: String
    let description: String?
    let prices: [Price]?
}

struct Price: Content {
    let id: Int?
    let cents: Int
    let active: Bool
    let activeTo: Date
    let activeFrom: Date
    let currency: String
}
