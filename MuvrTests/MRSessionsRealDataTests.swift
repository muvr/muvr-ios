import Foundation
import XCTest
@testable import Muvr
@testable import MuvrKit

class MRSessionsRealDataTests : XCTestCase {
    
    private func readSessions(properties: MKExercise.Id -> [MKExerciseProperty]) -> [MRLoadedSession] {
        let bundlePath = NSBundle(forClass: MRSessionsRealDataTests.self).pathForResource("Sessions", ofType: "bundle")!
        let bundle = NSBundle(path: bundlePath)!
        return bundle.pathsForResourcesOfType("csv", inDirectory: nil).map { path in
            return MRSesionLoader.read(path, properties: properties)
        }
    }
    
    func testRealData() {
        let app = MRAppDelegate()
        app.application(UIApplication.sharedApplication(), didFinishLaunchingWithOptions: nil)
        
        // First run score
        for loadedSession in readSessions(app.exercisePropertiesForExerciseId) {
            let message = "\(loadedSession.description) \(loadedSession.exerciseType)"
            try! app.startSession(forExerciseType: loadedSession.exerciseType)
            let firstScore = MRExerciseSessionEvaluator(loadedSession: loadedSession).evaluate(app.currentSession!)
            try! app.endCurrentSession()

            try! app.startSession(forExerciseType: loadedSession.exerciseType)
            let secondScore = MRExerciseSessionEvaluator(loadedSession: loadedSession).evaluate(app.currentSession!)
            try! app.endCurrentSession()
            
            XCTAssertGreaterThan(firstScore.labelsAccuracy(), 0.5, message)
            XCTAssertGreaterThan(firstScore.exercisesAccuracy(), 0.7, message)

            XCTAssertGreaterThan(secondScore.labelsAccuracy(), 0.5, message)
            XCTAssertGreaterThan(secondScore.exercisesAccuracy(), 0.8, message)
            
            XCTAssertGreaterThanOrEqual(secondScore.exercisesAccuracy(), firstScore.exercisesAccuracy(), message)
            XCTAssertLessThan(secondScore.totalCost(), firstScore.totalCost(), message)
        }
    }
    
}
