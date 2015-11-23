import Foundation
import XCTest
@testable import MuvrKit

class MKActivationFunctionPlusApplyOnTest : XCTestCase {
    
    func testIdentity() {
        var inputOutput = [Float](count: 5, repeatedValue: 1)
        MKActivationFunction.Identity.applyOn(&inputOutput, offset: 0, length: 5)
        XCTAssertEqual(inputOutput, [1, 1, 1, 1, 1])
    }
    
    func testRectlin() {
        var inputOutput: [Float] = [-2.0, -1.0, 0.0, 1.0, 2.0]
        MKActivationFunction.ReLU.applyOn(&inputOutput, offset: 0, length: 5)
        XCTAssertEqual(inputOutput, [0, 0, 0, 1, 2])
    }

    func testSigmoid() {
        var inputOutput: [Float] = [-100000, -1.0, 0.0, 1.0, 100000]
        MKActivationFunction.Sigmoid.applyOn(&inputOutput, offset: 0, length: 5)
        XCTAssertEqual(inputOutput, [0, 0.268941432, 0.5, 0.731058597, 1])
    }
    
    func testTanh() {
        var inputOutput: [Float] = [-100000, -1.0, 0.0, 1.0, 100000]
        MKActivationFunction.Tanh.applyOn(&inputOutput, offset: 0, length: 5)
        XCTAssertEqual(inputOutput, [-1, -0.761594176, 0, 0.761594176, 1])
    }
}
