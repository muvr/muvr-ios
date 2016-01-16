import Foundation
import XCTest
import MuvrKit
import CoreData
import CoreLocation
@testable import Muvr

class MRManagedExercisePlanTests : MRCoreDataTestCase {

    func testUpsert() {
        let plan = MKExercisePlan<MKExercise.Id>()
        let location = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let exerciseType = MKExerciseType.ResistanceTargeted(muscleGroups: [.Arms, .Legs])

        // the plan is not there to start with
        XCTAssertTrue(MRManagedExercisePlan.exactPlanForExerciseType(exerciseType, location: location, inManagedObjectContext: managedObjectContext) == nil)

        // upsert => insert
        MRManagedExercisePlan.upsertPlan(plan, exerciseType: exerciseType, location: location, inManagedObjectContext: managedObjectContext)
        XCTAssertTrue(MRManagedExercisePlan.exactPlanForExerciseType(exerciseType, location: location, inManagedObjectContext: managedObjectContext) != nil)
        
        // mutate plan
        plan.insert("foobar")
        
        // upsert again
        MRManagedExercisePlan.upsertPlan(plan, exerciseType: exerciseType, location: location, inManagedObjectContext: managedObjectContext)
        let loadedPlan = MRManagedExercisePlan.exactPlanForExerciseType(exerciseType, location: location, inManagedObjectContext: managedObjectContext)!.plan
        XCTAssertEqual(loadedPlan.next, ["foobar"])
    }

}
