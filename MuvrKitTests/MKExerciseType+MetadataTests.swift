import Foundation
import XCTest
@testable import MuvrKit

class MKExerciseTypePlusMetadataTests : XCTestCase {
    
    func testResistanceTargeted() {
        let l = MKExerciseType.ResistanceTargeted(muscleGroups: [.Arms, .Legs])
        let r = MKExerciseType(metadata: l.metadata)
        
        XCTAssertEqual(l, r)
    }
    
    func testResistanceWholeBody() {
        let l = MKExerciseType.ResistanceWholeBody
        let r = MKExerciseType(metadata: l.metadata)
        
        XCTAssertEqual(l, r)
    }
    
}
