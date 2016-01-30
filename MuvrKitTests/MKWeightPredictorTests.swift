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
        
        let weights: [[Double]] = [
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
        
        for s in 0..<weights.count {
            print("")
            predictors.forEach {name, predictor in
                let (_, error) = predictor.calculateError(Array(weights[s].dropLast()), forExerciseId: "biceps-curl", expectedValue: weights[s].last!)
                costs[name]? +=  error
                print("Session #\(s+1): \(name) cost: \(error)")
            }
        }
        
        print("")
        costs.forEach { name, cost in
            print("\(name) Total cost: \(cost)")
        }
        
    }

}