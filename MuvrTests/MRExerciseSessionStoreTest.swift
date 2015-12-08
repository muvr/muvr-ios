import Foundation
import XCTest
import MuvrKit
import CoreData
@testable import Muvr

class MRExerciseSessionStoreTest: MRCoreDataTestCase {

    func testSessionUpload() {
        let storage = MRLocalStorageAccess()
        let sessionStore = MRExerciseSessionStore(storageAccess: storage)
        
        let session = MRManagedExerciseSession.insertNewObject(inManagedObjectContext: managedObjectContext)
        
        session.completed = true
        session.start = NSDate(timeIntervalSinceNow: -60)
        session.end = NSDate()
        session.exerciseModelId = "arms"
        session.id = "some_random_id"
        session.sensorData = "someSensorData".dataUsingEncoding(NSUTF8StringEncoding)
        
        sessionStore.uploadSession(session) {
            XCTAssertEqual(2, storage.uploads.count)
            storage.reset()
        }
    }
    
}
