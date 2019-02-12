@testable import App
import Vapor
import XCTest

final class AppTests: XCTestCase {
    func testNothing() throws {
        XCTAssert(true)
    }

    static let allTests = [
        ("testNothing", testNothing)
    ]
}
