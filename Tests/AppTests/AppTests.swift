@testable import App
import Vapor
import XCTest

final class AppTests: XCTestCase {
    func testNothing() throws {
        // add your tests here
        XCTAssert(true)
    }
    
    func testCash() throws {
//        print("creating application")
//        let app = try Application()
//        let req = Request(using: app)
//        req.http.body = """
//        {
//            "hello": "world"
//        }
//        """.convertToHTTPBody()
//        req.http.contentType = .json
//        let c = CashPaymentMethod(request: req)
//        let res = try c.createTransaction(orderId: 1, userId: 1, amount: 100, status: Order.PaymentStatus.paid).wait()
//        print("res:", res)
//        var r = false
//        if (res.id! > 9) {
//            r = true
//        }
//        XCTAssert(r)
    }

    static let allTests = [
        ("testNothing", testNothing),
        ("testCash", testCash)
    ]
}
