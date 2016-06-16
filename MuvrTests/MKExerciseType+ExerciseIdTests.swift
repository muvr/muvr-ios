import Foundation
import XCTest
import MuvrKit
@testable import Muvr

class MKExerciseTypePlusExerciseIdTests : XCTestCase {
    
    
    func testConversion() {
        func go(_ l: MKExerciseType) {
            let r = MKExerciseType(exerciseId: l.exerciseIdPrefix)!
            XCTAssertEqual(l, r)
        }

        go(.IndoorsCardio)
        go(.ResistanceWholeBody)
        go(.ResistanceTargeted(muscleGroups: []))
        go(.ResistanceTargeted(muscleGroups: [.Arms]))
        go(.ResistanceTargeted(muscleGroups: [.Arms, .Legs]))
    }
    
}
