import Foundation
import XCTest
@testable import MuvrKit

class MKRegressionFitterTests : XCTestCase {
    
    func testX() {
        let x: [Float] = [1,2, 3,4] // 2x2 matrix
        let x_ = MKRegressionFitter.format(x, m: 2, degree: 2)
        
        // expect a 2x5 matrix where each row is [1, x0, x1, x0^2, x1^2]
        let expected: [Float] = [1,1,2,1,4, 1,3,4,9,16]
        
        XCTAssertEqual(expected, x_)
    }
    
    func testSolveX() {
        let d = 2
        let m = 2
        
        let x: [Float] = [10,20, 10,25, 15,25, 15,30] // 4x2
        let y: [Float] = [4, 4, 6, 8] // 1x4
        let a = MKRegressionFitter.solve(x, y: y, m: m, degree: d)
        
        XCTAssertEqual(m * d + 1, a.count)
        
        let n = x.count / m
        let k = a.count
        var res = [Float](count: n, repeatedValue: 0)
        for i in 0..<n {
            res[i] = a[0]
            for j in 1..<k {
                let c = (j-1) % m
                res[i] += a[j] * pow(x[i * m + c], ceil(Float(j) / Float(m)))
            }
        }
        
        for i in 0..<n {
            XCTAssertEqualWithAccuracy(y[i], res[i], accuracy: 0.05)
        }

    }
    
}