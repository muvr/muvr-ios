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

        go(.indoorsCardio)
        go(.resistanceWholeBody)
        go(.resistanceTargeted(muscleGroups: []))
        go(.resistanceTargeted(muscleGroups: [.arms]))
        go(.resistanceTargeted(muscleGroups: [.arms, .legs]))
    }
    
}
