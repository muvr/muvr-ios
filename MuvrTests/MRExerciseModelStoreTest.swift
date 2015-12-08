import Foundation
import XCTest
import MuvrKit
@testable import Muvr

class MRExerciseModelStoreTest: XCTestCase {
    
    private let storage = MRLocalStorageAccess()
    
    lazy var store: MRExerciseModelStore  = {
        return MRExerciseModelStore(storageAccess: self.storage)
    }()
    
    override func setUp() {
        super.setUp()
        storage.reset()
        store.reset()
    }
    
    override func tearDown() {
        storage.reset()
        store.reset()
    }
    
    func testLoadsBundledModels() {
        let storage = MRLocalStorageAccess()
        let store = MRExerciseModelStore(storageAccess: storage)
        // expect 2 models: arms and slacking
        XCTAssertEqual(2, store.models.count)
    }
    
    func testDownloadedModels() {
        let storage = MRLocalStorageAccess()
        let store = MRExerciseModelStore(storageAccess: storage)
        
        let data = "data".dataUsingEncoding(NSUTF8StringEncoding)!
        // add 1 new model
        storage.uploadFile("test_1_model.weights.raw", data: data) {}
        storage.uploadFile("test_1_model.layers.txt", data: data) {}
        storage.uploadFile("test_1_model.labels.txt", data: data) {}
        
        // add 1 more recent model
        storage.uploadFile("arms_1_model.weights.raw", data: data) {}
        storage.uploadFile("arms_1_model.layers.txt", data: data) {}
        storage.uploadFile("arms_1_model.labels.txt", data: data) {}
        
        store.downloadModels {
            // should have 3 models: slacking, arms and test
            XCTAssertEqual(3, store.models.count)
            storage.reset()
        }
    }
}
