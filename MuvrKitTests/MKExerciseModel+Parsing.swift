import Foundation
import XCTest
@testable import MuvrKit

class MKExerciseModelPlusParsingTest : XCTestCase {
    private let bundle = NSBundle(forClass: MuvrKitTests.self)
    
    func testLoadValid() {
        let model = try! MKExerciseModel(fromBundle: bundle, id: "arms")
        XCTAssertEqual(model.exerciseIds, ["arms/biceps-curl", "shoulders/lateral-raise", "arms/triceps-extension"])
    }
    
    func testLoadCompletelyMissing() {
        do {
            let _ = try MKExerciseModel(fromBundle: bundle, id: "not there at all")
            XCTFail("Not thrown")
        } catch MKExerciseModel.LoadError.MissingModelComponent(_) {
            // OK
        } catch {
            XCTFail("Bad exception")
        }
        
    }
    
}
