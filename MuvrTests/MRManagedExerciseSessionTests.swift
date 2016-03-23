import Foundation
import XCTest
import MuvrKit
@testable import Muvr

class MRManagedExerciseSessionTests : MRCoreDataTestCase {
    
    private func noRound(value: Double, exerciseId: String) -> Double {
        return value
    }

    func testClassificationHints() {
        let plan = MRManagedExercisePlan.insertNewObject(.AdHoc(exerciseType: .IndoorsCardio), location: nil, inManagedObjectContext: managedObjectContext)
        let session = MRManagedExerciseSession.insert("12312", plan: plan, start: NSDate(), location: nil, inManagedObjectContext: managedObjectContext)
        let givenDetail: MKExerciseDetail = MKExerciseDetail(id: "foo/bar", type: MKExerciseType.IndoorsCardio, muscle: nil, labels: [.Intensity], properties: [])
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
        let plan = MRManagedExercisePlan.insertNewObject(.AdHoc(exerciseType: .IndoorsCardio), location: nil, inManagedObjectContext: managedObjectContext)
        let session = MRManagedExerciseSession.insert("12312", plan: plan, start: NSDate(), location: nil, inManagedObjectContext: managedObjectContext)
        session.labelsPredictor = MKAverageLabelsPredictor(historySize: 1) { _, v, _ in return v }
        
        let givenDetail: MKExerciseDetail = MKExerciseDetail(id: "foo/bar", type: MKExerciseType.ResistanceWholeBody, muscle: nil, labels: [.Repetitions, .Weight, .Intensity], properties: [])
        let givenLabels: [MKExerciseLabel] = [.Repetitions(repetitions: 10), .Intensity(intensity: 0.5), .Weight(weight: 40)]
        
        session.addExerciseDetail(givenDetail, labels: givenLabels, start: NSDate(), duration: 10)
        XCTAssertEqual(session.predictDurationForExerciseDetail(givenDetail), 10)
        XCTAssertEqual(session.predictExerciseLabelsForExerciseDetail(givenDetail).0.count, 2)
        XCTAssertEqual(session.predictExerciseLabelsForExerciseDetail(givenDetail).1.count, 1)
        saveContext()
    }
    
    func testSimilarSessions() {
        let cardio = MRManagedExercisePlan.insertNewObject(.AdHoc(exerciseType: .IndoorsCardio), location: nil, inManagedObjectContext: managedObjectContext)
        let strength = MRManagedExercisePlan.insertNewObject(.AdHoc(exerciseType: .ResistanceWholeBody), location: nil, inManagedObjectContext: managedObjectContext)
        let session1 = MRManagedExerciseSession.insert("12341", plan: cardio, start: NSDate(), location: nil, inManagedObjectContext: managedObjectContext)
        session1.end = NSDate() // finish session 1
        let session2 = MRManagedExerciseSession.insert("12342", plan: strength, start: NSDate(), location: nil, inManagedObjectContext: managedObjectContext)
        session2.end = NSDate() // finish session 2
        let lastSession = MRManagedExerciseSession.insert("12343", plan: cardio, start: NSDate(), location: nil, inManagedObjectContext: managedObjectContext)
        lastSession.end = NSDate() // finish session 3
        XCTAssertEqual(2, lastSession.fetchSimilarSessionsSinceDate(NSDate(), inManagedObjectContext: managedObjectContext).count)
    }
    
}
