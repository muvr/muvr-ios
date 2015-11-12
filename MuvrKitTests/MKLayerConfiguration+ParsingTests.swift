import Foundation
import XCTest
@testable import MuvrKit

class MKLayerConfigurationPlusParsingTests : XCTestCase {
    
    func testParseSimple() {
        let parsed = try! MKLayerConfiguration.parse(text: "1 id 2 relu 3 tanh 4 sigmoid")
        
        XCTAssertEqual(parsed[0].activationFunction, MKActivationFunction.Identity)
        XCTAssertEqual(parsed[0].size, 1)

        XCTAssertEqual(parsed[1].activationFunction, MKActivationFunction.ReLU)
        XCTAssertEqual(parsed[1].size, 2)

        XCTAssertEqual(parsed[2].activationFunction, MKActivationFunction.Tanh)
        XCTAssertEqual(parsed[2].size, 3)
        
        XCTAssertEqual(parsed[3].activationFunction, MKActivationFunction.Sigmoid)
        XCTAssertEqual(parsed[3].size, 4)
    }
    
}
