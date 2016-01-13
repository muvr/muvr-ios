import Foundation
import XCTest
@testable import MuvrKit

class MKPolynomialFitterTests : XCTestCase {

    func testX() {
        let x = (0..<100).map { Float($0) }
        let y = (0..<100).map { Float($0) }
        let R = try! MKPolynomialFitter.fit(x: x, y: y, degree: 5)
        XCTAssertEqualWithAccuracy(R[0], 0, accuracy: 0.01)
        XCTAssertEqualWithAccuracy(R[1], 1, accuracy: 0.01)
        XCTAssertEqualWithAccuracy(R[2], 0, accuracy: 0.01)
        XCTAssertEqualWithAccuracy(R[3], 0, accuracy: 0.01)
        XCTAssertEqualWithAccuracy(R[4], 0, accuracy: 0.01)
    }
    
}
