import Foundation
import XCTest
import MuvrKit
@testable import Muvr

class MRSessionAppraiserTests : MRCoreDataTestCase {
    
    func testBasicAchievement() {
        let template = MRAppDelegate.sharedDelegate().predefinedSessionTypes.first!
        guard case .Predefined(let exercisePlan) = template else {
            XCTFail("Can't extract exercise plan from template")
            return
        }
        let plan = MRManagedExercisePlan.insertNewObject(template, location: nil, inManagedObjectContext: managedObjectContext)
        
        // no achievement yet (no sessions started)
        XCTAssertNil(MRSessionAppraiser().achievementForSessions([], plan: exercisePlan))
        
        // start 1st session
        let session1 = MRManagedExerciseSession.insert("12345", plan: plan, start: NSDate(), location: nil, inManagedObjectContext: managedObjectContext)
        session1.end = NSDate()
        
        // no achievement yet (1 session started)
        let similarSessions1 = session1.fetchSimilarSessionsSinceDate(NSDate(), inManagedObjectContext: managedObjectContext)
        XCTAssertNil(MRSessionAppraiser().achievementForSessions(similarSessions1, plan: exercisePlan))
        
        // start 2nd session
        let session2 = MRManagedExerciseSession.insert("12346", plan: plan, start: NSDate(), location: nil, inManagedObjectContext: managedObjectContext)
        session2.end = NSDate()
        
        // recieve the 'star' achievement
        let similarSessions2 = session2.fetchSimilarSessionsSinceDate(NSDate(), inManagedObjectContext: managedObjectContext)
        XCTAssertEqual("star", MRSessionAppraiser().achievementForSessions(similarSessions2, plan: exercisePlan))
    }
}