import Foundation
import XCTest
@testable import MuvrKit

class MKExercisePlanPlusJSONTests: XCTestCase {
    
    func testExercisePlanJsonSerialisation() {
        let exerciseType: MKExerciseType = .ResistanceTargeted(muscleGroups: [.Arms, .Chest, .Shoulders])
        let p1 = MKExercisePlan(exerciseType: exerciseType)
        
        p1.plan.insert("arms/biceps-curls")
        XCTAssertEqual(p1.plan.next.first!, "arms/biceps-curls")
        
        let json = p1.json
        let p2 = MKExercisePlan(json: json)!
        
        XCTAssertEqual(p2.id, p1.id)
        XCTAssertEqual(p2.name, p1.name)
        XCTAssertEqual(p2.exerciseType, p1.exerciseType)
        XCTAssertEqual(p2.plan.next, p1.plan.next)
    }
    
}