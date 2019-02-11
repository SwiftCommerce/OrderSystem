import Vapor

struct Product: Content {
    let id: Int?
    let sku: String
    let name: String
    let description: String?
    let prices: [Price]?
    
    func currenctPrice(for currency: String) -> Price? {
        guard self.prices != nil else { return nil }
        
        let now = Date()
        let validPrices = self.prices?.filter { price in
            return price.active && price.currency.lowercased() == currency.lowercased() && price.activeFrom <= now && price.activeTo > now
        }.sorted { $0.activeFrom > $1.activeFrom }
        
        return validPrices?.filter { $0.activeFrom == validPrices?.first?.activeFrom }.min { ($0.id ?? 0) > ($1.id ?? 0) }
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
