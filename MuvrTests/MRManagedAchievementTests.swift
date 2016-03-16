import Foundation
import XCTest
import CoreData
@testable import Muvr

class MRManagedAchievementTests : MRCoreDataTestCase {
    
    func testInsert() {
        // user has no achievement to start with
        XCTAssertTrue(MRManagedAchievement.find(inManagedObjectContext: managedObjectContext).isEmpty)
        
        // insert
        let p1 =  MRManagedExercisePlan.insertNewObject(.AdHoc(exerciseType: .IndoorsCardio), location: nil, inManagedObjectContext: managedObjectContext)
        let p2 =  MRManagedExercisePlan.insertNewObject(.AdHoc(exerciseType: .ResistanceWholeBody), location: nil, inManagedObjectContext: managedObjectContext)
        let cardioAchievement = MRManagedAchievement.insertNewObject("20min run", plan: p1, inManagedObjectContext: managedObjectContext)
        XCTAssertNotNil(cardioAchievement)
        
        XCTAssertEqual(1, MRManagedAchievement.find(inManagedObjectContext: managedObjectContext).count)
        XCTAssertEqual(1, MRManagedAchievement.findForPlan(p1, inManagedObjectContext: managedObjectContext).count)
        XCTAssertEqual(0, MRManagedAchievement.findForPlan(p2, inManagedObjectContext: managedObjectContext).count)
    }
    
}
