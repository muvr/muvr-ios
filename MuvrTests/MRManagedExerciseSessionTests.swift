import Foundation
import XCTest
import MuvrKit
@testable import Muvr

class MRManagedExerciseSessionTests : MRCoreDataTestCase {
    
    private func noRound(value: Double, exerciseId: String) -> Double {
        return value
    }

    func testClassificationHints() {
        let session = MRManagedExerciseSession.insert("12312", exerciseType: .IndoorsCardio, start: NSDate(), location: nil, inManagedObjectContext: managedObjectContext)
        let givenDetail: MKExerciseDetail = MKExerciseDetail(id: "foo/bar", type: MKExerciseType.IndoorsCardio, labels: [.Intensity], properties: [])
        let givenLabels: [MKExerciseLabel] = [.Repetitions(repetitions: 10)]
        session.setClassificationHint(givenDetail, labels: givenLabels)
        if case .ExplicitExercise(let start, let duration, let expected) = session.classificationHints.first! {
            XCTAssertEqualWithAccuracy(start, start, accuracy: 0.1)
            XCTAssertNil(duration)
            let (expectedDetail, expectedLabels) = expected.first!
            XCTAssertEqual(expectedDetail.id, givenDetail.id)
            XCTAssertEqual(expectedLabels.first, givenLabels.first)
        }
    }
    
    func testAddExerciseDetail() {
        let session = MRManagedExerciseSession.insert("12312", exerciseType: .IndoorsCardio, start: NSDate(), location: nil, inManagedObjectContext: managedObjectContext)
        session.plan = MRManagedExercisePlan.insertNewObject(.AdHoc(exerciseType: .IndoorsCardio), location: nil, inManagedObjectContext: managedObjectContext)
        session.labelsPredictor = MKAverageLabelsPredictor(historySize: 1) { _, v, _ in return v }
        
        let givenDetail: MKExerciseDetail = MKExerciseDetail(id: "foo/bar", type: MKExerciseType.ResistanceWholeBody, labels: [], properties: [])
        let givenLabels: [MKExerciseLabel] = [.Repetitions(repetitions: 10), .Intensity(intensity: 0.5), .Weight(weight: 40)]
        
        session.addExerciseDetail(givenDetail, labels: givenLabels, start: NSDate(), duration: 10)
        XCTAssertEqual(session.predictDurationForExerciseDetail(givenDetail), 10)
        XCTAssertEqual(session.predictExerciseLabelsForExerciseDetail(givenDetail).0.count, 2)
        XCTAssertEqual(session.predictExerciseLabelsForExerciseDetail(givenDetail).1.count, 1)
        saveContext()
    }
    
}
