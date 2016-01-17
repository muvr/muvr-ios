import Foundation
import MuvrKit
import XCTest

class MKExerciseTypeTests : XCTestCase {
    
    func testIsContainedWithin() {
        let session = MKExerciseType.ResistanceTargeted(muscleGroups: [.Arms, .Chest])
        let exercise = MKExerciseType.ResistanceTargeted(muscleGroups: [.Arms])
        
        XCTAssertTrue(exercise.isContainedWithin(session))
    }
    
}

