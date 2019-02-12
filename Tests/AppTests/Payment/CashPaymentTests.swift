import FluentMySQL
import Transaction
import XCTest
import Vapor
@testable import App

final class CashPaymentTests: XCTestCase {
    var app: Result<Application, AnyError> { return Application.testable() }
    
    func testCashPayment()throws {
        let connection = try app.get().databaseConnection(to: .mysql)
        
        let order = try Order().save(on: connection).wait()
        let items = try [
            Item(orderID: order.requireID(), productID: 12, quantity: 2, taxCode: nil)
        ].map { $0.save(on: connection) }.flatten(on: connection).wait()
        
        let controller = CashController(structure: .mixed)
        try controller.execute(Request(using: app.get()), body: VoidCodable()).wait()
    }
    
    static let allTests: [(String, (CashPaymentTests) -> ()throws -> ())] = [
        ("testCashPayment", testCashPayment)
    ]
}
