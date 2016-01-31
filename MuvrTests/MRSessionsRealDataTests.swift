import Foundation
import XCTest
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
            return MRSesionLoader.read(path, properties: properties)
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
        
        // Evaluate count sessions, giving the system the opportunity to learn the users
        // journey through the sessions
        let evaluatedSessions: [EvaluationResult] = readSessions(app.exercisePropertiesForExerciseId).map { loadedSession in
            let name = "\(loadedSession.description) \(loadedSession.exerciseType)"
            let scores: [MRExerciseSessionEvaluator.Result] = (0..<count).map { i in
                try! app.startSession(forExerciseType: loadedSession.exerciseType)
                let score = MRExerciseSessionEvaluator(loadedSession: loadedSession).evaluate(app.currentSession!)
                try! app.endCurrentSession()
                return score
            }
            return (name, loadedSession.exerciseType, scores)
        }
        
        // Perform basic assertions on the first (completely untrained) and last (completely trained)
        // session. When the assertions pass, the app provides acceptable user experience
        for (name, _, scores) in evaluatedSessions {
            let firstScore = scores.first!
            let lastScore = scores.last!
            
            XCTAssertLessThanOrEqual(firstScore.labelsWeightedLoss(), 5, name)
            XCTAssertGreaterThan(firstScore.labelsAccuracy(), 0.5, name)
            XCTAssertGreaterThan(firstScore.exercisesAccuracy(), 0.7, name)
            
            XCTAssertGreaterThan(lastScore.labelsAccuracy(), 0.8, name)
            XCTAssertGreaterThan(lastScore.exercisesAccuracy(), 0.8, name)
            XCTAssertLessThanOrEqual(lastScore.labelsWeightedLoss(), 1, name)
            
            XCTAssertGreaterThanOrEqual(lastScore.exercisesAccuracy(), firstScore.exercisesAccuracy(), name)
        }
        
        for (exerciseType, results) in (evaluatedSessions.groupBy { $0.1 }) {
            for i in 0..<count {
                let bla = project(results, index: i) { $0.labelsAccuracy() }.maxElement()
                let bwl = project(results, index: i) { $0.labelsWeightedLoss() }.minElement()
                let bea = project(results, index: i) { $0.exercisesAccuracy() }.maxElement()

                print("At \(i) for type \(exerciseType)")
                print("Best EA = \(bea)")
                print("Best LA = \(bla)")
                print("Best WL = \(bwl)")
                print("")
            }
        }
    }
    
}
