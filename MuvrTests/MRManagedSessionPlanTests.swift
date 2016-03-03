import Foundation
import XCTest
import MuvrKit
import CoreData
import CoreLocation
@testable import Muvr

class MRManagedSessionPlanTests : MRCoreDataTestCase {
    
    func testUpsert() {
        // the plan is not there to start with
        XCTAssertNil(MRManagedSessionPlan.find(inManagedObjectContext: managedObjectContext))
        
        // insert
        let sessionPlan = MRManagedSessionPlan.insertNewObject(MKMarkovPredictor<MKExercisePlan.Id>(), inManagedObjectContext: managedObjectContext)
        XCTAssertNotNil(MRManagedSessionPlan.find(inManagedObjectContext: managedObjectContext))
        
        // mutate plan
        sessionPlan.insert("foobar")
        
        // upsert again
        let loadedPlan = MRManagedSessionPlan.find(inManagedObjectContext: managedObjectContext)!.plan
        XCTAssertEqual(loadedPlan.next, ["foobar"])
    }
    
}
