import TaxCalculator
import Service

struct TaxCalculator {
    typealias Calculator = GenericTaxCalculator
    
    let container: Container
    
    init(container: Container) {
        self.container = container
    }
    
    func calculate(from input: (order: Order, currency: String)) -> Future<Decimal> {
        do {
            let calculator = try self.container.make(Calculator.self)
            let total = input.order.total(on: self.container, currency: input.currency)
            
            return total.map(Decimal.init(_:)).flatMap(calculator.tax)
        } catch let error {
            return self.container.future(error: error)
        }
    }
}
