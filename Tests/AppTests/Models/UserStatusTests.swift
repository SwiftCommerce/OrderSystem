import XCTest
@testable import App

final class UserStatusTests: XCTestCase {
    func testInit() {
        XCTAssertNotNil(User.Status(rawValue: 0))
        XCTAssertNotNil(User.Status(rawValue: 1))
        XCTAssertNotNil(User.Status(rawValue: 2))
        XCTAssertNotNil(User.Status(rawValue: 3))
        XCTAssertNotNil(User.Status(rawValue: 4))
        XCTAssertNotNil(User.Status(rawValue: 10))
        XCTAssertNotNil(User.Status(rawValue: 42))
        XCTAssertNotNil(User.Status(rawValue: Int.max))
    }
    
    func testRawValue() {
        XCTAssertEqual(User.Status.admin.rawValue, 0)
        XCTAssertEqual(User.Status.moderator.rawValue, 1)
        XCTAssertEqual(User.Status.standard.rawValue, 2)
        XCTAssertEqual(User.Status.other(3).rawValue, 3)
        XCTAssertEqual(User.Status.other(4).rawValue, 4)
        XCTAssertEqual(User.Status.other(10).rawValue, 10)
        XCTAssertEqual(User.Status.other(42).rawValue, 42)
        XCTAssertEqual(User.Status.other(Int.max).rawValue, Int.max)
    }
    
    func testStandardCases() {
        XCTAssertEqual(User.Status.admin, User.Status(rawValue: 0))
        XCTAssertEqual(User.Status.moderator, User.Status(rawValue: 1))
        XCTAssertEqual(User.Status.standard, User.Status(rawValue: 2))
    }
    
    static let allTests: [(String, (UserStatusTests) -> ()throws -> ())] = [
        ("testInit", testInit),
        ("testRawValue", testRawValue),
        ("testStandardCases", testStandardCases)
    ]
}
