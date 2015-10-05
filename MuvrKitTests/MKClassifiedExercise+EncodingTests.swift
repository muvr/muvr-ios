import Foundation
import XCTest
@testable import MuvrKit

class MKClassifiedExerciseEncodingTests : XCTestCase {
    
    func testEncodeSimplePebble() {
        
        func testWithTitle(title: String, nullIndex: Int) {
            let e = MKClassifiedExercise.Resistance(confidence: 1, exerciseId: "foo/bar", duration: 1, repetitions: 10, intensity: 0.5, weight: 47)
                .encode(.Pebble) { _ in return title }
            
            XCTAssertEqual(e.length, 29)
            
            let ptr = UnsafePointer<UInt8>(e.bytes)
            
            XCTAssertEqual(97, ptr[0])             // 'a'
            XCTAssertEqual(98, ptr[1])             // 'b'
            XCTAssertEqual(0,  ptr[nullIndex])     // NULL
            
            XCTAssertEqual(100,  ptr[24])          // confidence * 100
            XCTAssertEqual(10,   ptr[25])          // repetitions
            XCTAssertEqual(50,   ptr[26])          // intensity * 100
            XCTAssertEqual(47,   ptr[27])          // weight
            
        }
        
        testWithTitle("abcd1efgh2ijkl3mnop4qrs", nullIndex: 23)            // exact length
        testWithTitle("abcd1efgh2ijkl3mnop4qrs********", nullIndex: 23)    // over
        testWithTitle("ab", nullIndex: 3)                                  // under
    }

    
    func testEncodeBareMinimum() {
        let e = MKClassifiedExercise.Resistance(confidence: 1, exerciseId: "foo/bar", duration: 1, repetitions: nil, intensity: nil, weight: nil)
            .encode(.Pebble) { _ in return "Foo Bar" }
        
        XCTAssertEqual(e.length, 29)
        
        let ptr = UnsafePointer<UInt8>(e.bytes)
        
        XCTAssertEqual(100,  ptr[24])          // confidence * 100
        XCTAssertEqual(0,    ptr[25])          // repetitions
        XCTAssertEqual(0,    ptr[26])          // intensity * 100
        XCTAssertEqual(0,    ptr[27])          // weight
    }
    
}
