import Foundation
import XCTest
@testable import MuvrKit

class MKMarkovPredictorTests : XCTestCase {

    
    func testSequence(sequence: [Double], forExerciseId exerciseId: String, desiredValue: Double) {
        let predictor = MKMarkovPredictor()
        for element in sequence {
            predictor.trainPositional([element], forExerciseId: exerciseId)
        }
        XCTAssertEqual(predictor.predictScalarForExerciseId(exerciseId, n: sequence.count), desiredValue)
    }
    
    func testPrediction() {
        testSequence([10.0, 15, 20, 25, 30, 35, 30, 30, 15, 20], forExerciseId: "exerciseA", desiredValue: 25)
        
        testSequence([10, 12.5, 15, 17.5, 17.5, 15, 15, 15, 12.5, 12.5, 12.5, 10, 10, 12.5], forExerciseId: "exerciseA", desiredValue: 15)
        
        testSequence([10.0, 15, 20, 25, 30, 35, 30, 30, 10.0, 15, 20, 25, 30, 35], forExerciseId: "exerciseA", desiredValue: 30)
        
        testSequence([10.0, 15, 20, 25, 30, 35, 30, 30, 10.0, 15, 20, 25, 30, 35, 30, 30, 10, 10, 10], forExerciseId: "exerciseA", desiredValue: 10)
    }
    
    func testTrainInProgress() {
        
        let predictor = MKMarkovPredictor()
        let id = "exerciseA"
        predictor.trainPositional([10], forExerciseId: id)
        XCTAssertEqual(predictor.predictScalarForExerciseId(id, n: 1), 10)
        
        predictor.trainPositional([10, 15], forExerciseId: id)
        XCTAssertEqual(predictor.predictScalarForExerciseId(id, n: 2), 10)
        
        predictor.trainPositional([10, 15, 20], forExerciseId: id)
        XCTAssertEqual(predictor.predictScalarForExerciseId(id, n: 3), 10)

        predictor.trainPositional([10, 15, 20, 25], forExerciseId: id)
        XCTAssertEqual(predictor.predictScalarForExerciseId(id, n: 3), 15)
        
        predictor.trainPositional([10, 15, 20, 25, 25], forExerciseId: id)
        XCTAssertEqual(predictor.predictScalarForExerciseId(id, n: 3), 25)
        
        predictor.trainPositional([10, 15, 20, 25, 25, 20], forExerciseId: id)
        XCTAssertEqual(predictor.predictScalarForExerciseId(id, n: 3), 25)
    }
}