import Foundation
import XCTest
@testable import MuvrKit

class MKExercisePlanPlusJSONTests : XCTestCase {
    
    func testIdentity() {
        let p1 = MKExercisePlan<String>()
        p1.insert("biceps-curl")
        p1.insert("triceps-extension")
        p1.insert("biceps-curl")
        
        let json = p1.json { $0 }
        let p2 = MKExercisePlan<String>.fromJsonFirst(json) { $0 as? String }!
        
        XCTAssertEqual(p2.next.first!, "biceps-curl")
        p2.insert("biceps-curl")
        XCTAssertEqual(p2.next.first!, "triceps-extension")
        p2.insert("triceps-extension")
        XCTAssertEqual(p2.next.first!, "biceps-curl")
    }
    
}
