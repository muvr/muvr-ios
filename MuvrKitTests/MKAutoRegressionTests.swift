import Foundation
import XCTest
@testable import MuvrKit

class MKAutoRegressionTests : XCTestCase {
    
    func testARLeastSquares() {
        let x = (0..<100).map { Float($0) }
        let a = try! MKAutoRegression.leastSquares(x, order: 5)
        let l = x.count - 1
        var next:Float = 0
        for i in 0..<a.count {
            next += a[i] * x[l-i]
        }
        XCTAssertEqualWithAccuracy(next, 100, accuracy: 0.1)
    }
    
    func testARLeastSquares2() {
        let x: [Float] = [10.0, 12.5, 15.0, 17.5, 20, 22.5, 25]
        let a = try! MKAutoRegression.leastSquares(x, order: 5)
        let l = x.count - 1
        var next:Float = 0
        for i in 0..<a.count {
            next += a[i] * x[l-i]
        }
        print(a)
        print(next)
        XCTAssertEqualWithAccuracy(next, 27.5, accuracy: 0.1)
    }
    
    func testARMaxEnt() {
        let x = (0..<100).map { Float($0) }
        let a = try! MKAutoRegression.maxEntropy(x, order: 5)
        let l = x.count - 1
        var next:Float = 0
        for i in 0..<a.count {
            next += a[i] * x[l-i]
        }
        XCTAssertEqualWithAccuracy(next, 100, accuracy: 0.1)
    }
    
    func testARMaxEntropy2() {
        let x: [Float] = [10.0, 12.5, 15.0, 17.5, 20, 22.5, 25]
        let a = try! MKAutoRegression.maxEntropy(x, order: 5)
        let l = x.count - 1
        var next:Float = 0
        for i in 0..<a.count {
            next += a[i] * x[l-i]
        }
        print(a)
        print(next)
        XCTAssertEqualWithAccuracy(next, 27.5, accuracy: 0.1)
    }
    
}