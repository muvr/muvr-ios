import Foundation
import XCTest
@testable import MuvrKit

class MKWeightPredictorTests : XCTestCase {
    
    func roundValue(value: Double, forExerciseId exerciseId: MKExercise.Id) -> Double {
        return MKScalarRounderFunction.roundMinMax(value, minimum: 2.5, step: 2.5, maximum: nil)
    }
    
    func testBigDrop1() {
        let predictor1 = MKPolynomialFittingScalarPredictor(round: roundValue)
        let predictor2 = MKMarkovPredictor()
        
        let sequence = [10.0, 12, 12, 14, 16, 16, 15, 10]
        let error1 = predictor1.calculateError(sequence, forExerciseId: "A", expectedValue: 12)
        let error2 = predictor2.calculateError(sequence, forExerciseId: "A", expectedValue: 12)

        NSLog("\n\nPolynomial error:\n\(error1)")
        NSLog("\n\nMarkov error:\n\(error2)")
        XCTAssertEqual(error1.1, 138.75)
        XCTAssertEqual(error2.1, 121)
    }
    
    func testBigDrop2() {
        let predictor1 = MKPolynomialFittingScalarPredictor(round: roundValue)
        let predictor2 = MKMarkovPredictor()
        
        let sequence = [10.0, 15, 20, 25, 30, 35, 30, 30, 9, 13]
        let error1 = predictor1.calculateError(sequence, forExerciseId: "A", expectedValue: 12)
        let error2 = predictor2.calculateError(sequence, forExerciseId: "A", expectedValue: 12)
        
        XCTAssertEqual(error1.1, 24407.75)
        XCTAssertEqual(error2.1, 1879)
    }
    
    func testHighJump1() {
        let predictor1 = MKPolynomialFittingScalarPredictor(round: roundValue)
        let predictor2 = MKMarkovPredictor()
        
        let sequence = [10.0, 15, 20, 25, 30, 35, 30, 30]
        let error1 = predictor1.calculateError(sequence, forExerciseId: "A", expectedValue: 12)
        let error2 = predictor2.calculateError(sequence, forExerciseId: "A", expectedValue: 12)
        
        XCTAssertEqual(error1.1, 4185.25)
        XCTAssertEqual(error2.1, 1149)
    }
    
    func testHighJump2() {
        let predictor1 = MKPolynomialFittingScalarPredictor(round: roundValue)
        let predictor2 = MKMarkovPredictor()
        
        let sequence = [15.0, 20, 25, 30, 35, 40, 35, 35]
        let error1 = predictor1.calculateError(sequence, forExerciseId: "A", expectedValue: 12)
        let error2 = predictor2.calculateError(sequence, forExerciseId: "A", expectedValue: 12)
        
        XCTAssertEqual(error1.1, 4815.25)
        XCTAssertEqual(error2.1, 1384)
    }
    
    func testPredictors() {
        
        let predictors: [String: MKScalarPredictor] = [
            "Polynomial" : MKPolynomialFittingScalarPredictor(round: roundValue),
            "Cubic" : MKPolynomialFittingScalarPredictor(round: roundValue, maxDegree: 3),
            "Markov" : MKMarkovPredictor(),
            "Markov (inc)" : MKMarkovPredictor(mode: .Inc),
            "Markov (mult)" : MKMarkovPredictor(mode: .Mult, round: roundValue),
            "Linear" : MKPolynomialFittingScalarPredictor(round: roundValue, maxDegree: 1, maxSamples: 2),
            "Last value": MKPolynomialFittingScalarPredictor(round: roundValue, maxDegree: 0, maxSamples: 1),
            "AR LeastSquares": MKAutoRegressionScalarPredictor(round: roundValue, order: 5, method: .LeastSquares),
            "AR MaxEntropy": MKAutoRegressionScalarPredictor(round: roundValue, order: 5, method: .MaxEntropy),
            "Corrected Linear": MKLinearMarkovScalarPredictor(round: roundValue, progression: { _ in return 2.5 })
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
                let (_, error) = predictor.calculateError(Array(weights[s].dropLast()), forExerciseId: "biceps-curl", expectedValue: weights[s].last!, debug: name == "Corrected Linear")
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