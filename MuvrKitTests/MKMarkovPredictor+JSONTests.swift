import Foundation
import XCTest
@testable import MuvrKit

class MKMarkovPredictorPlusJSONTests : XCTestCase {
    
    func testIdentity() {
        let p1 = MKMarkovPredictor<String>()
        p1.insert("biceps-curl")
        p1.insert("triceps-extension")
        p1.insert("biceps-curl")
        
        let json = p1.json { $0 }
        let p2 = MKMarkovPredictor<String>(json: json) { $0 as? String }!
        
        // From now on p1 and p2 should always predict the same outcome
        XCTAssertEqual(p2.next.first!, p1.next.first!)
        
        p1.insert("biceps-curl")
        p2.insert("biceps-curl")
        XCTAssertEqual(p2.next.first!, p1.next.first!)
        
        p1.insert("triceps-extension")
        p2.insert("triceps-extension")
        XCTAssertEqual(p2.next.first!, p1.next.first!)
    }
    
}
