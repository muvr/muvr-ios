import Foundation
import XCTest
@testable import MuvrKit

class MKExercisePlanPlusJSONTests: XCTestCase {
    
    func testExercisePlanJsonSerialisation() {
        let exerciseType: MKExerciseType = .ResistanceTargeted(muscleGroups: [.Arms, .Chest, .Shoulders])
        let exercise = MKExercisePlanItem(id: "arms/biceps-curls", duration: nil, rest: nil, labels: nil)
        let p1 = MKExercisePlan(id: NSUUID().UUIDString, name: "Test JSON plan", exerciseType: exerciseType, items: [exercise])
        
        XCTAssertEqual(p1.plan.next.first!, exercise.id)
        
        let json = p1.json
        let p2 = MKExercisePlan(json: json, filename: nil)!
        
        XCTAssertEqual(p2.id, p1.id)
        XCTAssertEqual(p2.name, p1.name)
        XCTAssertEqual(p2.exerciseType, p1.exerciseType)
        XCTAssertEqual(p2.plan.next, p1.plan.next)
        XCTAssertEqual(p2.items.count, p1.items.count)
    }
    
}