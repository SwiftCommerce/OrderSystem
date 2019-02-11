import XCTest
@testable import App

infix operator +

final class CombinableTests: XCTestCase {
    func testCombineSomeSome() {
        let a: Int? = 1
        let b: Int? = 1
        
        XCTAssertEqual(a + b, 2)
    }
    
    func testCombineSomeNone() {
        let a: Int? = 1
        let b: Int? = nil
        
        XCTAssertEqual(a + b, 1)
    }
    
    func testCombineNoneSome() {
        let a: Int? = nil
        let b: Int? = 1
        
        XCTAssertEqual(a + b, 1)
    }
    
    func testCombineNoneNone() {
        let a: Int? = nil
        let b: Int? = nil
        
        XCTAssertEqual(a + b, nil)
    }
    
    func testCombineOptionalNonOptional() {
        let a: Int = 1
        let b: Int? = nil
        
        XCTAssertEqual(a + b, 1)
        XCTAssertEqual(b + a, 1)
    }
    
    static let allTests: [(String, (CombinableTests) -> ()throws -> ())] = [
        ("testCombineSomeSome", testCombineSomeSome),
        ("testCombineSomeNone", testCombineSomeNone),
        ("testCombineNoneSome", testCombineNoneSome),
        ("testCombineNoneNone", testCombineNoneNone),
        ("testCombineOptionalNonOptional", testCombineOptionalNonOptional)
    ]
}
