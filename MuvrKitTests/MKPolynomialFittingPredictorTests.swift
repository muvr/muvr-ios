import Foundation
import XCTest
@testable import MuvrKit

class MKPolynomialFittingPredictorTests : XCTestCase {
    private func distinctValuesForKey(key: MKExerciseId) -> [Float]? {
        if key == "biceps-curl" {
            return [10, 12.5, 15, 17.5]
        }
        
        return nil
    }
    
    func testConstantPattern() {
        let predictor = MKPolynomialFittingPredictor<MKExerciseId>(distinctValuesForKey: distinctValuesForKey)
        let weights: [Double] = [Double](count: 20, repeatedValue: 10)
        try! predictor.trainPositional(weights, forKey: "biceps-curl")

        for (i, actual) in weights.enumerate() {
            let predicted = predictor.predicAt(i, forKey: "biceps-curl")!
            XCTAssertEqual(predicted, actual)
        }
    }
    
    func testInterestingPattern() {
        let predictor = MKPolynomialFittingPredictor<MKExerciseId>(distinctValuesForKey: distinctValuesForKey)

        // a more adventurous may do 10, 12.5, 15, 17.5, 17.5, 15, 15, 15, 12.5, 12.5, 10 progression
        let weights: [Double] = [10, 12.5, 15, 17.5, 17.5, 15, 15, 15, 12.5, 12.5, 12.5, 10]
        try! predictor.trainPositional(weights, forKey: "biceps-curl")
        
        for (i, actual) in weights.enumerate() {
            let predicted = predictor.predicAt(i, forKey: "biceps-curl")
            XCTAssertEqual(predicted, actual)
        }
    }
    
    
}
