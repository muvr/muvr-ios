import Foundation
import XCTest
import Accelerate

class MRRepetitionsEstimatorTests: XCTestCase {
    func testFindNoPeaks(){
        let estimator = MRRepetitionsEstimator()
        XCTAssertEqual(estimator.findPeaks([1, 1, 1]), [])
        XCTAssertEqual(estimator.findPeaks([1, 2, 3]), [])
        XCTAssertEqual(estimator.findPeaks([3, 2, 1]), [])
    }
    
    func testFindPeaks(){
        let estimator = MRRepetitionsEstimator()
        XCTAssertEqual(estimator.findPeaks([1, 2, 3, 5, 3, 1, 4, 7, 4, 3, 5, 5, 1]), [3, 7, 10])
    }
    
    func testAutocorrelation(){
        let estimator = MRRepetitionsEstimator()

        var result = estimator.autocorrelation([1, 2, 3, 5, 3, 1])
        let target = [1.0, 0.673469387755102, 0.102040816326531, -0.428571428571429, -0.795918367346939, -0.959183673469388]
        for r in 0...target.count-1 {
            XCTAssertEqualWithAccuracy(result[r], target[r], 0.001)
        }
    }
}