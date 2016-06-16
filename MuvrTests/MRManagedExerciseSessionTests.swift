import Foundation
import XCTest
import MuvrKit
@testable import Muvr

class MRManagedExerciseSessionTests : MRCoreDataTestCase {
    
    private func noRound(_ value: Double, exerciseId: String) -> Double {
        return value
    }

    func testClassificationHints() {
        let plan = MRManagedExercisePlan.insertNewObject(.adHoc(exerciseType: .indoorsCardio), location: nil, inManagedObjectContext: managedObjectContext)
        let session = MRManagedExerciseSession.insert("12312", plan: plan, start: Date(), location: nil, inManagedObjectContext: managedObjectContext)
        let givenDetail: MKExerciseDetail = MKExerciseDetail(id: "foo/bar", type: MKExerciseType.indoorsCardio, muscle: nil, labels: [.intensity], properties: [])
        let givenLabels: [MKExerciseLabel] = [.repetitions(repetitions: 10)]
        session.setClassificationHint(givenDetail, labels: givenLabels)
        if case .explicitExercise(let start, let duration, let expected) = session.classificationHints.first! {
            XCTAssertEqualWithAccuracy(start, start, accuracy: 0.1)
            XCTAssertNil(duration)
            let (expectedDetail, expectedLabels) = expected.first!
            XCTAssertEqual(expectedDetail.id, givenDetail.id)
            XCTAssertEqual(expectedLabels.first, givenLabels.first)
        }
    }
    
    func testAddExerciseDetail() {
        let plan = MRManagedExercisePlan.insertNewObject(.adHoc(exerciseType: .indoorsCardio), location: nil, inManagedObjectContext: managedObjectContext)
        let session = MRManagedExerciseSession.insert("12312", plan: plan, start: Date(), location: nil, inManagedObjectContext: managedObjectContext)
        session.labelsPredictor = MKAverageLabelsPredictor(historySize: 1) { _, v, _ in return v }
        
        let givenDetail: MKExerciseDetail = MKExerciseDetail(id: "foo/bar", type: MKExerciseType.resistanceWholeBody, muscle: nil, labels: [.repetitions, .weight, .intensity], properties: [])
        let givenLabels: [MKExerciseLabel] = [.repetitions(repetitions: 10), .intensity(intensity: 0.5), .weight(weight: 40)]
        
        session.addExerciseDetail(givenDetail, labels: givenLabels, start: Date(), duration: 10)
        let (predicted, missing) = session.predictExerciseLabelsForExerciseDetail(givenDetail)
        XCTAssertEqual(predicted.1, 10)
        XCTAssertEqual(predicted.0.count, 2)
        XCTAssertEqual(missing.0.count, 1)
        saveContext()
    }
    
    func testSimilarSessions() {
        let cardio = MRManagedExercisePlan.insertNewObject(.adHoc(exerciseType: .indoorsCardio), location: nil, inManagedObjectContext: managedObjectContext)
        let strength = MRManagedExercisePlan.insertNewObject(.adHoc(exerciseType: .resistanceWholeBody), location: nil, inManagedObjectContext: managedObjectContext)
        let session1 = MRManagedExerciseSession.insert("12341", plan: cardio, start: Date(), location: nil, inManagedObjectContext: managedObjectContext)
        session1.end = Date() // finish session 1
        let session2 = MRManagedExerciseSession.insert("12342", plan: strength, start: Date(), location: nil, inManagedObjectContext: managedObjectContext)
        session2.end = Date() // finish session 2
        let lastSession = MRManagedExerciseSession.insert("12343", plan: cardio, start: Date(), location: nil, inManagedObjectContext: managedObjectContext)
        lastSession.end = Date() // finish session 3
        XCTAssertEqual(2, lastSession.fetchSimilarSessionsSinceDate(Date(), inManagedObjectContext: managedObjectContext).count)
    }
    
}
