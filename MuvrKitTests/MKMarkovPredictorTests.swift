import Foundation
import XCTest
@testable import MuvrKit

class MKMarkovPredictorTests : XCTestCase {

    
    func testSequence(sequence: [Double], forExerciseId exerciseId: String, desiredValue: Double) {
        let predictor = MKMarkovPredictor()
        predictor.trainPositional(sequence, forExerciseId: exerciseId)
        XCTAssertEqual(predictor.predictScalarForExerciseId(exerciseId, n: sequence.count), desiredValue)
    }
    
    func testPrediction() {
        testSequence([10.0, 15, 20, 25, 30, 35, 30, 30, 15, 20], forExerciseId: "exerciseA", desiredValue: 25)
        
        testSequence([10, 12.5, 15, 17.5, 17.5, 15, 15, 15, 12.5, 12.5, 12.5, 10, 10, 13], forExerciseId: "exerciseA", desiredValue: 17.5)
        
        testSequence([10.0, 15, 20, 25, 30, 35, 30, 30, 10.0, 15, 20, 25, 30, 35], forExerciseId: "exerciseA", desiredValue: 30)
        
        testSequence([10.0, 15, 20, 25, 30, 35, 30, 30, 10.0, 15, 20, 25, 30, 35, 30, 30, 10, 10, 10], forExerciseId: "exerciseA", desiredValue: 10)
    }
}