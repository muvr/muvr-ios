import Foundation
import XCTest
import MuvrKit
@testable import Muvr

class MRExerciseModelTest: XCTestCase {
    
    private var urls: [NSURL] {
        let dir = NSURL(fileURLWithPath: NSTemporaryDirectory())
        return [
            dir.URLByAppendingPathComponent("arms_1_model.weights.raw"),
            dir.URLByAppendingPathComponent("arms_1_model.layers.txt"),
            dir.URLByAppendingPathComponent("arms_1_model.labels.txt"),
            dir.URLByAppendingPathComponent("arms_2_model.weights.raw"),
            dir.URLByAppendingPathComponent("arms_2_model.layers.txt"),
            dir.URLByAppendingPathComponent("arms_2_model.labels.txt"),
            dir.URLByAppendingPathComponent("chest_1_model.weights.raw"),
            dir.URLByAppendingPathComponent("chest_1_model.layers.txt"),
            dir.URLByAppendingPathComponent("chest_1_model.labels.txt"),
            dir.URLByAppendingPathComponent("not_a_model.txt"),
            dir.URLByAppendingPathComponent("chest_2_model.weights.raw"),
            dir.URLByAppendingPathComponent("chest_2_model.layers.txt")
        ]
    }
    
    func testFilenameParsing() {
        let validFile = "arms_12_model.weights.raw"
        let (id, version, type) = MRExerciseModel.parseFilename(validFile)!
        XCTAssertEqual("arms", id)
        XCTAssertEqual(12, version)
        XCTAssertEqual(MRExerciseModelFileType.Weights, type)
        
        let badVersionFile = "arms_1.0_model.weights.raw"
        XCTAssertNil(MRExerciseModel.parseFilename(badVersionFile))
        
        let badTypeFile = "arms_14_model.network.csv"
        XCTAssertNil(MRExerciseModel.parseFilename(badTypeFile))
    }
    
    func testModelsFromURLs() {
        let models = MRExerciseModel.models(urls)
        XCTAssertEqual(3, models.count)
    }
    
    func testLatestModels() {
        let models = MRExerciseModel.latestModels(urls)
        XCTAssertEqual(2, models.count)
    }
    
}
