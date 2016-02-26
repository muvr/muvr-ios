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
        let givenDetail: MKExerciseDetail = ("foo/bar", MKExerciseType.IndoorsCardio, [])
        let givenLabels: [MKExerciseLabel] = [.Repetitions(repetitions: 10)]
        session.setClassificationHint(givenDetail, labels: givenLabels)
        if case .ExplicitExercise(let start, let duration, let expected) = session.classificationHints.first! {
            XCTAssertEqualWithAccuracy(start, start, accuracy: 0.1)
            XCTAssertNil(duration)
            let (expectedDetail, expectedLabels) = expected.first!
            XCTAssertEqual(expectedDetail.0, givenDetail.0)
            XCTAssertEqual(expectedLabels.first, givenLabels.first)
        }
    }
    
    func testAddExerciseDetail() {
        let session = MRManagedExerciseSession.insert("12312", exerciseType: .IndoorsCardio, start: NSDate(), location: nil, inManagedObjectContext: managedObjectContext)
        session.plan = MKMarkovPredictor<MKExercise.Id>()
        session.labelsPredictor = MKAverageLabelsPredictor(historySize: 1) { _, v, _ in return v }
        
        let givenDetail: MKExerciseDetail = ("foo/bar", MKExerciseType.ResistanceWholeBody, [])
        let givenLabels: [MKExerciseLabel] = [.Repetitions(repetitions: 10), .Intensity(intensity: 0.5), .Weight(weight: 40)]
        
        session.addExerciseDetail(givenDetail, labels: givenLabels, start: NSDate(), duration: 10)
        XCTAssertEqual(session.predictDurationForExerciseDetail(givenDetail), 10)
        XCTAssertEqual(session.predictExerciseLabelsForExerciseDetail(givenDetail).0.count, 3)
        XCTAssertEqual(session.predictExerciseLabelsForExerciseDetail(givenDetail).1.count, 0)
        saveContext()
    }
    
}
