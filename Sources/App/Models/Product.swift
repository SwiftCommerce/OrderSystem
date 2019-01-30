import Vapor

struct Product: Content {
    let id: Int?
    let sku: String
    let name: String
    let description: String?
    let prices: [Price]?
    
    func currenctPrice(for currency: String) -> Price? {
        let now = Date()
        let validPrices = self.prices?.filter { price in
            return price.active && price.currency.lowercased() == currency.lowercased() && price.activeFrom <= now && price.activeTo > now
        }.sorted { first, second in
            return first.activeFrom > second.activeFrom
        }
        
        return validPrices?.first
    }
}

struct Price: Content {
    let id: Int?
    let cents: Int
    let active: Bool
    let activeTo: Date
    let activeFrom: Date
    let currency: String
}
