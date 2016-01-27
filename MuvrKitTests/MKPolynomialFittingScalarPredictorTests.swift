import Foundation
import XCTest
@testable import MuvrKit

class MKPolynomialFittingScalarPredictorTests : XCTestCase {
    
    func roundValue(value: Double, forExerciseId exerciseId: MKExercise.Id) -> Double {
        return MKScalarRounderFunction.roundMinMax(value, minimum: 2.5, step: 2.5, maximum: nil)
    }
    
    func testConstantPattern() {
        let predictor = MKPolynomialFittingScalarPredictor(round: roundValue)
        let linearPredictor = MKPolynomialFittingScalarPredictor(round: roundValue, maxDegree: 1, maxSamples: 2)
        let weights: [Double] = [Double](count: 20, repeatedValue: 10)
        predictor.trainPositional(weights, forExerciseId: "biceps-curl")
        linearPredictor.trainPositional(weights, forExerciseId: "biceps-curl")
        for (i, actual) in weights.enumerate() {
            let predicted = predictor.predictScalarForExerciseId("biceps-curl", n: i)!
            XCTAssertEqual(predicted, actual)
            let linearPrediction = linearPredictor.predictScalarForExerciseId("biceps-curl", n: i)!
            XCTAssertEqual(linearPrediction, actual)
        }
    }
    
    func testInterestingPattern() {
        let predictor = MKPolynomialFittingScalarPredictor(round: roundValue)
        
        // a more adventurous may do 10, 12.5, 15, 17.5, 17.5, 15, 15, 15, 12.5, 12.5, 10 progression
        let weights: [Double] = [10, 12.5, 15, 17.5, 17.5, 15, 15, 15, 12.5, 12.5, 12.5, 10, 10, 12.5]
        predictor.trainPositional(weights, forExerciseId: "biceps-curl")
        
        for (i, actual) in weights.enumerate() {
            let predicted = predictor.predictScalarForExerciseId("biceps-curl", n: i)!
            XCTAssertEqual(predicted, actual)
        }
        print(String(data: predictor.json, encoding: NSUTF8StringEncoding)!)
    }
    
    func testTrainInProgress() {
        let predictor = MKPolynomialFittingScalarPredictor(round: roundValue)
        let linearPredictor = MKPolynomialFittingScalarPredictor(round: roundValue, maxDegree: 1, maxSamples: 3)
        
        // first, we seem to be going in a linear fashion
        predictor.trainPositional([10], forExerciseId: "biceps-curl")
        linearPredictor.trainPositional([10], forExerciseId: "biceps-curl")

        // after the first element, we just get the last value
        XCTAssertEqual(predictor.predictScalarForExerciseId("biceps-curl", n: 1)!, 10)
        XCTAssertEqual(linearPredictor.predictScalarForExerciseId("biceps-curl", n: 1)!, 10)
        
        predictor.trainPositional([10, 12.5], forExerciseId: "biceps-curl")
        linearPredictor.trainPositional([10, 12.5], forExerciseId: "biceps-curl")
        XCTAssertEqual(predictor.predictScalarForExerciseId("biceps-curl", n: 2)!, 15)
        XCTAssertEqual(linearPredictor.predictScalarForExerciseId("biceps-curl", n: 2)!, 15)
        
        // then, we level off: it's getting tough, we might even drop
        predictor.trainPositional([10, 12.5, 15], forExerciseId: "biceps-curl")
        predictor.trainPositional([10, 12.5, 15, 15], forExerciseId: "biceps-curl")
        predictor.trainPositional([10, 12.5, 15, 15, 15], forExerciseId: "biceps-curl")
        linearPredictor.trainPositional([10, 12.5, 15], forExerciseId: "biceps-curl")
        linearPredictor.trainPositional([10, 12.5, 15, 15], forExerciseId: "biceps-curl")
        linearPredictor.trainPositional([10, 12.5, 15, 15, 15], forExerciseId: "biceps-curl")
        XCTAssertEqual(predictor.predictScalarForExerciseId("biceps-curl", n: 5)!, 12.5)
        XCTAssertEqual(linearPredictor.predictScalarForExerciseId("biceps-curl", n: 5)!, 15)
    }
    
}
