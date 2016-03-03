import Foundation
import XCTest
import MuvrKit
import CoreData
import CoreLocation
@testable import Muvr

class MRManagedExercisePlanTests : MRCoreDataTestCase {

    func testUpsert() {
        let location = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let exerciseType = MKExerciseType.ResistanceTargeted(muscleGroups: [.Arms, .Legs])

        // the plan is not there to start with
        XCTAssertNil(MRManagedExercisePlan.exactPlanForExerciseType(exerciseType, location: location, inManagedObjectContext: managedObjectContext))

        // insert
        let exercisePlan = MRManagedExercisePlan.insertNewObject(.AdHoc(exerciseType: exerciseType), location: location, inManagedObjectContext: managedObjectContext)
        XCTAssertNotNil(MRManagedExercisePlan.exactPlanForExerciseType(exerciseType, location: location, inManagedObjectContext: managedObjectContext))
        
        // mutate plan
        exercisePlan.insert("foobar")
        exercisePlan.save()
        
        // upsert again
        let loadedPlan = MRManagedExercisePlan.exactPlanForExerciseType(exerciseType, location: location, inManagedObjectContext: managedObjectContext)!.plan
        XCTAssertEqual(loadedPlan.next, ["foobar"])
    }
    
    func testChangeLocation() {
        let location0 = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let exerciseType = MKExerciseType.ResistanceTargeted(muscleGroups: [.Arms, .Legs])
        let sessionType = MRSessionType.AdHoc(exerciseType: exerciseType)
        
        let planAtLoc0 = MRManagedExercisePlan.planForSessionType(sessionType, location: location0, inManagedObjectContext: managedObjectContext)
        planAtLoc0.insert("foobar")
        planAtLoc0.save()
        
        let location1 = CLLocationCoordinate2D(latitude: 1, longitude: 1)
        let planAtLoc1 = MRManagedExercisePlan.planForSessionType(sessionType, location: location1, inManagedObjectContext: managedObjectContext)
        XCTAssertEqual(planAtLoc1.next, ["foobar"])
        
        planAtLoc1.insert("foobaz")
        planAtLoc1.save()
        
        let loadedPlan1 = MRManagedExercisePlan.planForSessionType(sessionType, location: location1, inManagedObjectContext: managedObjectContext)
        XCTAssertEqual(loadedPlan1.next, ["foobar", "foobaz"])
        
        let loadedPlan0 = MRManagedExercisePlan.planForSessionType(sessionType, location: location0, inManagedObjectContext: managedObjectContext)
        XCTAssertEqual(loadedPlan0.next, ["foobar"])
    }

}
