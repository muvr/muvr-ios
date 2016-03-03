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
        
        // upsert again
        let loadedPlan = MRManagedExercisePlan.exactPlanForExerciseType(exerciseType, location: location, inManagedObjectContext: managedObjectContext)!.plan
        XCTAssertEqual(loadedPlan.next, ["foobar"])
    }

}
