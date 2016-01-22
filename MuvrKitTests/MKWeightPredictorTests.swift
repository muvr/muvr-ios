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

}