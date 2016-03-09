import Foundation
import XCTest
@testable import MuvrKit

class MKMuscleTests : XCTestCase {

    func testMuscleGroups() {
        let muscleGroups: [MKMuscleGroup] = [.Arms, .Back, .Chest, .Core, .Legs, .Shoulders]
        for muscleGroup in muscleGroups {
            for muscle in muscleGroup.muscles {
                XCTAssertEqual(muscle.muscleGroup, muscleGroup)
            }
        }
    }
    
}