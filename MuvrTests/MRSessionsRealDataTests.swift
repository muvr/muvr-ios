import Foundation
import XCTest
import CoreLocation
@testable import Muvr
@testable import MuvrKit

extension Array {
    
    func groupBy<A : Hashable>(f: Element -> A) -> [A : [Element]] {
        var result: [A:[Element]] = [:]
        for element in self {
            let key = f(element)
            let values = result[key] ?? []
            result[key] = values + [element]
        }
        return result
    }
    
}

///
/// Loads real sessions in the ``Sessions`` bundle, and uses the real ``MRAppDelegate`` machinery to
/// simulate the user going through these exercises. This test runs through all submitted sessions.
///
/// There are some hard assertions that we can make about the label weighted loss, exercise and label
/// accuracy. Values that fail these tests will result in very poor user experience.
///
/// TODO: save the results (best, average), and use these results in future tests. This way, we can
/// TODO: be sure that the code keeps improving.
///
class MRSessionsRealDataTests : XCTestCase {
    
    private typealias EvaluationResult = (String, MKExerciseType, [MRExerciseSessionEvaluator.Result])
    
    private func readSessions(properties: MKExercise.Id -> [MKExerciseProperty]) -> [MRLoadedSession] {
        let bundlePath = NSBundle(forClass: MRSessionsRealDataTests.self).pathForResource("Sessions", ofType: "bundle")!
        let bundle = NSBundle(path: bundlePath)!
        return bundle.pathsForResourcesOfType("csv", inDirectory: nil).map { path in
            return MRSessionLoader.read(path, properties: properties)
        }
    }
    
    private func project<A>(evaluatedSessions: [EvaluationResult], index: Int, f: MRExerciseSessionEvaluator.Result -> A) -> [A] {
        return evaluatedSessions.map { e in
            let (_, _, results) = e
            return f(results[index])
        }
    }
    
    func testTimeless() {
        let count = 3
        let app = MRAppDelegate()
        app.application(UIApplication.sharedApplication(), didFinishLaunchingWithOptions: nil)
        // At Kingfisher
        app.locationManager(CLLocationManager(), didUpdateLocations: [CLLocation(latitude: 53.435739, longitude: -2.165993)])
        
        // Evaluate count sessions, giving the system the opportunity to learn the users
        // journey through the sessions
        let evaluatedSessions: [EvaluationResult] = readSessions(app.exercisePropertiesForExerciseId).map { loadedSession in
            let name = "\(loadedSession.description) \(loadedSession.exerciseType)"
            let results: [MRExerciseSessionEvaluator.Result] = (0..<count).map { i in
                try! app.startSession(forExerciseType: loadedSession.exerciseType)
                let score = MRExerciseSessionEvaluator(loadedSession: loadedSession).evaluate(app.currentSession!)
                try! app.endCurrentSession()
                return score
            }
            return (name, loadedSession.exerciseType, results)
        }
        
        // Perform basic assertions on the first (completely untrained) and last (completely trained)
        // session. When the assertions pass, the app provides acceptable user experience
        for (name, _, results) in evaluatedSessions {
            let firstResult = results.first!
            let lastResult = results.last!
            
            XCTAssertLessThanOrEqual(firstResult.labelsWeightedLoss(.NumberOfTaps), 2, name)
            XCTAssertGreaterThanOrEqual(firstResult.labelsAccuracy(), 0.5, name)
            XCTAssertGreaterThan(firstResult.exercisesAccuracy(), 0.7, name)
            
            XCTAssertGreaterThan(lastResult.labelsAccuracy(), 0.8, name)
            XCTAssertGreaterThan(lastResult.exercisesAccuracy(), 0.8, name)
            XCTAssertLessThanOrEqual(lastResult.labelsWeightedLoss(.NumberOfTaps), 1, name)
            
            // Overall, the last result must be better than the first result
            XCTAssertGreaterThanOrEqual(lastResult.labelsAccuracy(), firstResult.labelsAccuracy(), name)
            XCTAssertGreaterThanOrEqual(lastResult.exercisesAccuracy(), firstResult.exercisesAccuracy(), name)
            XCTAssertLessThanOrEqual(lastResult.labelsWeightedLoss(.NumberOfTaps), firstResult.labelsWeightedLoss(.RawValue), name)
        }
        
        for (exerciseType, results) in (evaluatedSessions.groupBy { $0.1 }) {
            let last = results.last!
            print(last.0)
            print(last.2.last!.description)
            for i in 0..<count {
                let bla = project(results, index: i) { $0.labelsAccuracy() }.maxElement()
                let bwl = project(results, index: i) { $0.labelsWeightedLoss(.RawValue) }.minElement()
                let bea = project(results, index: i) { $0.exercisesAccuracy() }.maxElement()

                print("Best EA = \(bea)")
                print("Best LA = \(bla)")
                print("Best WL = \(bwl)")
                print("")
            }
        }
    }
    
}
