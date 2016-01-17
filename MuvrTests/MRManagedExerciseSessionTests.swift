import Foundation
import XCTest
import MuvrKit
@testable import Muvr

class MRManagedExerciseSessionTests : MRCoreDataTestCase {

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
        let givenDetail: MKExerciseDetail = ("foo/bar", MKExerciseType.IndoorsCardio, [])
        let givenLabels: [MKExerciseLabel] = [.Repetitions(repetitions: 10)]
        
        session.addExerciseDetail(givenDetail, labels: givenLabels, start: NSDate(), duration: 10, inManagedObjectContext: managedObjectContext)
        saveContext()
    }
    
}
