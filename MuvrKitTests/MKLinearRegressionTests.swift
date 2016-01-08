import Foundation
import XCTest
@testable import MuvrKit

class MKLinearRegressionTests : XCTestCase {

    func testX() {
        let X = (0..<100).map { Double($0 / 25) }
        let Y = (0..<100).map { Double($0) }
        let R = MKLinearRegression().univariate(X: X, Y: Y)
        print(R)
    }
    
}
