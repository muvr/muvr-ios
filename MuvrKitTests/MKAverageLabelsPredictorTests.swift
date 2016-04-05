import Foundation
import XCTest
@testable import MuvrKit

class MKAverageLabelsPredictorTests: XCTestCase {

    func testPredictNewHistory() {
        let predictor = MKAverageLabelsPredictor(historySize: 3, round: { _, value, _ in return value })
        let bicepsCurl = MKExerciseDetail(id: "biceps-curl", type: .ResistanceTargeted(muscleGroups: [.Arms]), muscle: .Biceps, labels: [.Repetitions, .Weight], properties: [])
        let labels: MKExerciseLabelsWithDuration = ([.Repetitions(repetitions: 10), .Weight(weight: 7.5)], 11.0, 10.0)
        // 1st workout with 2 sets of biceps curls
        predictor.correctLabelsForExercise(bicepsCurl, labels: labels)
        predictor.correctLabelsForExercise(bicepsCurl, labels: labels)
        predictor.saveCurrentWorkout()
        
        // 2nd workout with 3 sets of biceps curls
        // 1st should be predicted from history of the 1st set
        var predicted = predictor.predictLabelsForExercise(bicepsCurl)!
        XCTAssertEqual(labels.0.count, predicted.0.count)
        XCTAssertEqual(labels.1, predicted.1)
        predictor.correctLabelsForExercise(bicepsCurl, labels: labels)
        // 2nd should be predicted from history of the 1st set
        predicted = predictor.predictLabelsForExercise(bicepsCurl)!
        XCTAssertEqual(labels.0.count, predicted.0.count)
        XCTAssertEqual(labels.1, predicted.1)
        predictor.correctLabelsForExercise(bicepsCurl, labels: labels)
        // 3rd should be inferred from previous sets as it was not in 1st workout
        predicted = predictor.predictLabelsForExercise(bicepsCurl)!
        XCTAssertEqual(labels.0.count, predicted.0.count)
        XCTAssertEqual(labels.1, predicted.1)
    }
    
}