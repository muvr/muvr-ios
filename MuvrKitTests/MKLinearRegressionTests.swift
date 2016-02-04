import Foundation
import XCTest
@testable import MuvrKit

class MKRegressionFitterTests : XCTestCase {
    
    func testFormatX() {
        let x: [Float] = [1,2, 3,4] // 2x2 matrix
        let x_ = MKLinearRegression.format(x, m: 2, degree: 2)
        
        // expect a 2x5 matrix where each row is [1, x0, x1, x0^2, x1^2]
        let expected: [Float] = [1,1,2,1,4, 1,3,4,9,16]
        
        XCTAssertEqual(expected, x_)
    }
    
    func testTrainX() {
        let d = 2
        let m = 2
        
        let x: [Float] = [10,20, 10,25, 15,25, 15,30] // 4x2
        let y: [Float] = [4, 4, 6, 8] // 1x4
        let θ = MKLinearRegression.train(x, y: y, m: m, degree: d)
        
        XCTAssertEqual(m * d + 1, θ.count)
        
        let n = x.count / m
        for i in 0..<n {
            let row = Array(x[(i*m)..<(i+1)*m])
            let res = MKLinearRegression.estimate(row, θ: θ)
            XCTAssertEqualWithAccuracy(y[i], res, accuracy: 0.05)
        }
    }
    
    func testTrainXDropDim() {
        let d = 2
        let m = 2
        
        let x: [Float] = [1,20, 1,25, 1,25, 1,30] // 4x2
        let y: [Float] = [4, 6, 6, 8] // 1x4
        let θ = MKLinearRegression.train(x, y: y, m: m, degree: d)
        
        print(θ)
        XCTAssertEqual(0, θ[1])
        XCTAssertEqual(0, θ[3])
        
        let n = x.count / m
        for i in 0..<n {
            let row = Array(x[(i*m)..<(i+1)*m])
            let res = MKLinearRegression.estimate(row, θ: θ)
            XCTAssertEqualWithAccuracy(y[i], res, accuracy: 0.05)
        }
    }
    
}