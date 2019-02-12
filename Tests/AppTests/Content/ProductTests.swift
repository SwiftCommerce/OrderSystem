import XCTest
@testable import App

final class ProductTests: XCTestCase {
    let now = Date()
    let earlierDate = Date(timeInterval: -3600, since: Date())
    var product: Product {
        return Product(
            id: -1,
            sku: UUID().uuidString,
            name: "Fizz Buzz",
            description: "A developer walks into a Foo Bar...",
            prices: [
                Price(id: 0, cents: 1000, active: false, activeTo: Date.distantFuture, activeFrom: self.now, currency: "USD"),
                Price(id: 1, cents: 1100, active: false, activeTo: Date.distantFuture, activeFrom: self.now, currency: "EUR"),
                Price(id: 2, cents: 2000, active: true, activeTo: Date.distantFuture, activeFrom: self.now, currency: "USD"),
                Price(id: 3, cents: 2750, active: true, activeTo: Date.distantFuture, activeFrom: self.now, currency: "EUR"),
                Price(id: 4, cents: 3050, active: true, activeTo: Date.distantFuture, activeFrom: self.now, currency: "USD"),
                Price(id: 5, cents: 4999, active: true, activeTo: Date.distantFuture, activeFrom: self.now, currency: "EUR"),
                Price(id: 6, cents: 5000, active: true, activeTo: Date.distantFuture, activeFrom: self.earlierDate, currency: "USD"),
                Price(id: 7, cents: 7777, active: true, activeTo: Date.distantFuture, activeFrom: self.earlierDate, currency: "EUR"),
                Price(id: 8, cents: 8080, active: true, activeTo: Date.distantFuture, activeFrom: self.earlierDate, currency: "USD"),
                Price(id: 9, cents: 9876, active: true, activeTo: Date.distantFuture, activeFrom: self.earlierDate, currency: "EUR")
            ])
    }
    
    func testCurrentPrice()throws {
        let usd = Price(id: 4, cents: 3050, active: true, activeTo: Date.distantFuture, activeFrom: self.now, currency: "USD")
        let eur = Price(id: 5, cents: 4999, active: true, activeTo: Date.distantFuture, activeFrom: self.now, currency: "EUR")
        
        let foundUSD = self.product.currenctPrice(for: "usd")
        XCTAssertEqual(usd.id, foundUSD?.id)
        XCTAssertEqual(usd.cents, foundUSD?.cents)
        XCTAssertEqual(usd.active, foundUSD?.active)
        XCTAssertEqual(usd.activeTo, foundUSD?.activeTo)
        XCTAssertEqual(usd.activeFrom, foundUSD?.activeFrom)
        XCTAssertEqual(usd.currency, foundUSD?.currency)
        
        let foundEUR = self.product.currenctPrice(for: "eur")
        XCTAssertEqual(eur.id, foundEUR?.id)
        XCTAssertEqual(eur.cents, foundEUR?.cents)
        XCTAssertEqual(eur.active, foundEUR?.active)
        XCTAssertEqual(eur.activeTo, foundEUR?.activeTo)
        XCTAssertEqual(eur.activeFrom, foundEUR?.activeFrom)
        XCTAssertEqual(eur.currency, foundEUR?.currency)
    }
    
    static let allTests: [(String, (ProductTests) -> ()throws -> ())] = [
        ("testCurrentPrice", testCurrentPrice)
    ]
}
