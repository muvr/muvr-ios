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
}