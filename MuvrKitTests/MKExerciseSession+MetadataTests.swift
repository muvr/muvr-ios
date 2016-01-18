import Foundation
import XCTest
@testable import MuvrKit

class MKExerciseSessionPlusMetadataTests : XCTestCase {
    
    func testExerciseSessionToMetadata() {
        let now = NSDate()
        let originalSession = MKExerciseSession(id: "id", start: now, end: nil, completed: false, exerciseType: .ResistanceWholeBody)
        let metadata = originalSession.metadata
        XCTAssertNotNil(metadata["id"])
        XCTAssertNotNil(metadata["start"])
        XCTAssertNil(metadata["end"])
        XCTAssertNotNil(metadata["completed"])
        XCTAssertNotNil(metadata["exerciseType"])
        
        guard let session = MKExerciseSession(metadata: metadata) else {
            XCTFail("Failed to build MKExerciseSession from metadata")
            return
        }
        XCTAssertEqual(originalSession.id, session.id)
        XCTAssertEqual(originalSession.start, session.start)
        XCTAssertEqual(originalSession.end, session.end)
        XCTAssertEqual(originalSession.completed, session.completed)
        XCTAssertEqual(originalSession.exerciseType, session.exerciseType)
    }
    
}