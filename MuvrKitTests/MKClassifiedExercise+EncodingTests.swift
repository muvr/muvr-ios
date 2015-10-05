import Foundation
import XCTest
@testable import MuvrKit

class MKClassifiedExerciseEncodingTests : XCTestCase {
    
    func testEncodeSimple() {
        let e = MKClassifiedExercise.Resistance(confidence: 0.65, exerciseId: "foo/bar", duration: 1, repetitions: 64, intensity: 0.64, weight: 64).encode(.Pebble) { _ in return "Foobar" }
        
        print(e)
        
    }
    
}
