import Foundation
import XCTest
@testable import MuvrKit

class MKActivationFunctionPlusApplyOnTest : XCTestCase {
    
    func testIdentity() {
        let input = [Float](count: 10, repeatedValue: 1)
        var inputOutput = input
        MKActivationFunction.Identity.applyOn(&inputOutput, offset: 0, length: 10)
        XCTAssertEqual(inputOutput, input)
    }
    
}
