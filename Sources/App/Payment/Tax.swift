import TaxCalculator
import Vapor
import MySQL

struct TaxCalculator {
    typealias Calculator = GenericTaxCalculator
    typealias Result = (total: Decimal, items: [String: Decimal])
    
    let container: Container
    
    init(container: Container) {
        self.container = container
    }
    
    func calculate(from input: (order: Order, currency: String)) -> Future<Result> {
        return container.databaseConnection(to: .mysql).flatMap { conn in
            return input.order.items(with: conn)
        }.flatMap { items in
            let rate = try self.container.make(Calculator.self).percentage / 100
            
            return try self.container.make(ProductRepository.self).get(products: items.map { $0.productID }).map { products in
                let data = zip(products, items).compactMap { element -> (Item, Product, String, Decimal)? in
                    guard let product = element.0 else { return nil }
                    return (element.1, product, input.currency, rate)
                }
                let items = try data.map(self.tax).reduce(into: [:]) { $0[$1.id] = $1.value }
                let total = items.reduce(0) { result, cost in result + cost.value }
                
                return (total, items)
                
            }
        }
    }
    
    func tax(for item: Item, and product: Product, currency: String, rate: Decimal)throws -> (id: String, value: Decimal) {
        guard let price = product.prices?.filter({ $0.currency.lowercased() == currency.lowercased() && $0.active }).first else {
            throw Abort(.failedDependency, reason: "No price for product '\(product.sku)' with currency '\(currency)'")
        }
        
        return try (item.requireID().description, Decimal(price.cents) * rate)
    }
}
