import Foundation
import XCTest
@testable import MuvrKit

class MKPolynomialFittingWeightPredictorTests : XCTestCase, MKExercisePropertySource {
    
    func exercisePropertiesForExerciseId(exerciseId: MKExerciseId) -> [MKExerciseProperty] {
        if exerciseId == "biceps-curl" {
            return [.WeightProgression(minimum: 2.5, increment: 2.5, maximum: nil)]
        }
        
        return []
    }
    
    func testConstantPattern() {
        let predictor = MKPolynomialFittingWeightPredictor(exercisePropertySource: self)
        let weights: [Double] = [Double](count: 20, repeatedValue: 10)
        try! predictor.trainPositional(weights, forExerciseId: "biceps-curl")

        for (i, actual) in weights.enumerate() {
            let predicted = predictor.predictWeightForExerciseId("biceps-curl", n: i)!
            XCTAssertEqual(predicted, actual)
        }
    }
    
    func testInterestingPattern() {
        let predictor = MKPolynomialFittingWeightPredictor(exercisePropertySource: self)

        // a more adventurous may do 10, 12.5, 15, 17.5, 17.5, 15, 15, 15, 12.5, 12.5, 10 progression
        let weights: [Double] = [10, 12.5, 15, 17.5, 17.5, 15, 15, 15, 12.5, 12.5, 12.5, 10, 10, 12.5]
        try! predictor.trainPositional(weights, forExerciseId: "biceps-curl")
        
        for (i, actual) in weights.enumerate() {
            let predicted = predictor.predictWeightForExerciseId("biceps-curl", n: i)!
            XCTAssertEqual(predicted, actual)
        }
        
        print(String(data: predictor.json, encoding: NSUTF8StringEncoding)!)
    }
    
    
}
