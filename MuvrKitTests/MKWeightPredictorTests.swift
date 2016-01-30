import Foundation
import XCTest
@testable import MuvrKit

class MKWeightPredictorTests : XCTestCase {
    
    func roundValue(value: Double, forExerciseId exerciseId: MKExercise.Id) -> Double {
        return MKScalarRounderFunction.roundMinMax(value, minimum: 2.5, step: 2.5, maximum: nil)
    }
    
    func step(value: Double, n: Int, forExerciseId exerciseId: MKExercise.Id) -> Double {
        return value + Double(n) * 2.5
    }
    
    func testPredictors() {
        
        let predictors: [String: MKScalarPredictor] = [
            "Polynomial" : MKPolynomialFittingScalarPredictor(round: roundValue),
            "Cubic" : MKPolynomialFittingScalarPredictor(round: roundValue, maxDegree: 3),
            "Linear" : MKPolynomialFittingScalarPredictor(round: roundValue, maxDegree: 1, maxSamples: 2),
            "Last value": MKPolynomialFittingScalarPredictor(round: roundValue, maxDegree: 0, maxSamples: 1),
            "Corrected Linear": MKLinearMarkovScalarPredictor(round: roundValue, step: step, maxDegree: 1, maxSamples: 2, maxCorrectionSteps: 2)
        ]
        
        let weightSequences: [[Double]] = [
            [10, 12.5, 15, 17.5, 17.5, 15, 15, 15, 12.5, 12.5, 12.5, 10, 10, 12.5],
            [10, 12.5, 15, 17.5, 17.5, 15, 15, 15, 12.5, 12.5, 12.5, 10, 10, 12.5],
            [10, 12.5, 15, 17.5, 17.5, 15, 15, 15, 12.5, 12.5, 12.5, 10, 10, 12.5],
            [17.5, 17.5, 15, 15, 15, 12.5, 12.5, 12.5, 10, 10, 12.5],
            [17.5, 17.5, 15, 15, 15, 12.5, 12.5, 12.5, 10, 10, 12.5],
            [17.5, 17.5, 15, 15, 15, 12.5, 12.5, 12.5, 10, 10, 12.5],
            [10, 12.5, 15, 17.5, 20, 15, 15, 15, 12.5, 12.5, 12.5, 10, 10, 12.5],
            [10, 12.5, 15, 17.5, 20, 15, 15, 15, 12.5, 12.5, 12.5, 10, 10, 12.5],
            [10, 12.5, 15, 17.5, 20, 15, 15, 15, 12.5, 12.5, 12.5, 10, 10, 12.5],
            [12.5, 15, 17.5, 17.5, 15, 15, 12.5, 12.5, 12.5, 10, 10, 12.5],
            [12.5, 15, 17.5, 17.5, 15, 15, 12.5, 12.5, 12.5, 10, 10, 12.5],
            [12.5, 15, 17.5, 17.5, 15, 15, 12.5, 12.5, 12.5, 10, 10, 12.5],
            [10, 12.5, 15, 17.5, 17.5, 20, 20, 15, 15, 12.5, 12.5, 10, 10, 10, 15, 15],
            [10, 12.5, 15, 17.5, 17.5, 20, 20, 15, 15, 12.5, 12.5, 10, 10, 10, 15, 15],
            [10, 12.5, 15, 17.5, 17.5, 20, 20, 15, 15, 12.5, 12.5, 10, 10, 10, 15, 15]
        ]
        
        var costs: [String:Double] = [:]
        predictors.keys.forEach { costs[$0] = 0 }
        
        for (name, predictor) in predictors {
            print("************\n")
            print(name)
            for weightSequence in weightSequences {
                var weights: [Double] = []
                for (index, weight) in weightSequence.enumerate() {
                    weights.append(weight)
                    predictor.trainPositional(weights, forExerciseId: "biceps-curl")
                    let prediction = predictor.predictScalarForExerciseId("biceps-curl", n: weights.count) ?? 999
                    if index + 1 < weightSequence.count {
                        let expected = weightSequence[index + 1]
                        print(expected - prediction)
                    }
                }
            }
        }
    }

}