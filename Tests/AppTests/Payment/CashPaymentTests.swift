import FluentMySQL
import Transaction
import JWTVapor
import XCTest
import Vapor
@testable import App

final class CashPaymentTests: XCTestCase {
    var app: Application!
    var connection: MySQLConnection!
    
    override func setUp() {
        super.setUp()
        
        self.app = try! Application.testable().get()
        self.connection = try! app.newConnection(to: .mysql).wait()
    }
    
    func testCashPayment()throws {
        try self.app.make(Logger.self).warning("ProductManager service must be running on port 8080 for this test to pass")
        
        let order = try Order().save(on: self.connection).wait()
        _ = try Item(orderID: order.requireID(), productID: 17, quantity: 2, taxCode: nil).save(on: connection).wait()
        
        let http = try HTTPRequest(
            method: .POST,
            url: URL(string: "/v1/orders/\(order.requireID())/payment/cash")!,
            headers: ["Content-Type": "application/json", "Authorization": "Bearer \(self.token())"],
            body: JSONEncoder().encode(PaymentGenerationContent(
                currency: "USD",
                shipping: 3000,
                shippingDiscount: 1200,
                handling: 1500,
                insurence: 2000,
                giftWrap: 250
            ))
        )
        let request = Request(http: http, using: self.app)
        
        let responder = try self.app.make(Responder.self)
        let response = try responder.respond(to: request).wait()
        
        let payment = try response.content.decode(Order.Payment.self).wait()
        try XCTAssertEqual(payment.orderID, order.requireID())
        XCTAssertEqual(payment.paymentMethod, "cash")
        XCTAssertEqual(payment.currency, "USD")
        XCTAssertEqual(payment.shipping, 3000)
        XCTAssertEqual(payment.shippingDiscount, 1200)
        XCTAssertEqual(payment.handling, 1500)
        XCTAssertEqual(payment.insurence, 2000)
        XCTAssertEqual(payment.giftWrap, 250)
        
        
        // Cleanup
        try Order.Payment.query(on: connection).filter(\.orderID == order.requireID()).delete().wait()
        try Address.query(on: connection).filter(\.orderID == order.requireID()).delete().wait()
        try Item.query(on: connection).filter(\.orderID == order.requireID()).delete().wait()
        try Order.query(on: connection).filter(\.id == order.requireID()).delete().wait()
    }
    
    func token()throws -> String {
        let signer = try self.app.make(JWTService.self)
        let iat = Date().timeIntervalSince1970
        let exp = Date(timeInterval: 3600, since: Date()).timeIntervalSince1970
        let user = User(exp: exp, iat: iat, email: "test@example.com", id: -1, status: .admin)
        
        return try signer.sign(user)
    }
    
    static let allTests: [(String, (CashPaymentTests) -> ()throws -> ())] = [
        ("testCashPayment", testCashPayment)
    ]
}
