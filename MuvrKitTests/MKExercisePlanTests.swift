import Foundation
import XCTest
@testable import MuvrKit

class MKExercisePlanTests: XCTestCase {

    func testEmptyExercisePlan() {
        let exerciseType: MKExerciseType = .ResistanceTargeted(muscleGroups: [.Arms, .Chest, .Shoulders])
        let plan = MKExercisePlan(exerciseType: exerciseType)
        XCTAssertEqual(plan.id.characters.count, 36)
        XCTAssertEqual(plan.name, "arms, chest, shoulders")
        XCTAssertEqual(plan.exerciseType, exerciseType)
        XCTAssertTrue(plan.plan.next.isEmpty)
    }
    
}