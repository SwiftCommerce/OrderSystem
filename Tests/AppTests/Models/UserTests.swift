import XCTest
import JWTVapor
@testable import App

final class UserTests: XCTestCase {
    func testExpireClaim()throws {
        let iat = Date(timeInterval: -3601, since: Date()).timeIntervalSince1970
        let exp = Date(timeInterval: -1, since: Date()).timeIntervalSince1970
        let user = User(exp: exp, iat: iat, email: "guest@example.com", id: -1, status: .admin)
        
        let signer = JWTSigner.hs256(key: "weak-key")
        try XCTAssertNoThrow(user.verify(using: signer))
    }
    
    static let allTests: [(String, (UserTests) -> ()throws -> ())] = [
        ("testExpireClaim", testExpireClaim)
    ]
}
