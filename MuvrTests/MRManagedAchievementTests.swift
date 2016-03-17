import Foundation
import XCTest
import CoreData
@testable import Muvr

class MRManagedAchievementTests : MRCoreDataTestCase {
    
    func testInsert() {
        // user has no achievement to start with
        XCTAssertTrue(MRManagedAchievement.fetchAchievements(inManagedObjectContext: managedObjectContext).isEmpty)
        
        // insert
        let p1 =  MRManagedExercisePlan.insertNewObject(.AdHoc(exerciseType: .IndoorsCardio), location: nil, inManagedObjectContext: managedObjectContext)
        let p2 =  MRManagedExercisePlan.insertNewObject(.AdHoc(exerciseType: .ResistanceWholeBody), location: nil, inManagedObjectContext: managedObjectContext)
        let cardioAchievement = MRManagedAchievement.insertNewObject("20min run", plan: p1, inManagedObjectContext: managedObjectContext)
        XCTAssertNotNil(cardioAchievement)
        
        XCTAssertEqual(1, MRManagedAchievement.fetchAchievements(inManagedObjectContext: managedObjectContext).count)
        XCTAssertEqual(1, MRManagedAchievement.fetchAchievementsForPlan(p1, inManagedObjectContext: managedObjectContext).count)
        XCTAssertEqual(0, MRManagedAchievement.fetchAchievementsForPlan(p2, inManagedObjectContext: managedObjectContext).count)
    }
    
}
