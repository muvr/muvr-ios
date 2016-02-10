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
    
    private func readPreviousScores() -> [String: [String: Double]] {
        let bundlePath = NSBundle(forClass: MRSessionsRealDataTests.self).pathForResource("Sessions", ofType: "bundle")!
        let bundle = NSBundle(path: bundlePath)!
        let fileName = bundle.pathForResource("_results_.json", ofType: nil)!
        let json = try! NSJSONSerialization.JSONObjectWithData(NSData(contentsOfFile: fileName)!, options: .AllowFragments)
        return json as! [String: [String: Double]]
    }
    
    private func writeTestScores(scores: [String: AnyObject]) {
        let bundlePath = NSBundle(forClass: MRSessionsRealDataTests.self).pathForResource("Sessions", ofType: "bundle")!
        let bundle = NSBundle(path: bundlePath)!
        let fileName = bundle.pathForResource("_results_.json", ofType: nil)!
        let json = try! NSJSONSerialization.dataWithJSONObject(scores, options: [.PrettyPrinted])
        json.writeToFile(fileName, atomically: true)
        
        print("Test scores written to \(fileName)\n")
        print("Consider updating _results_.json in sessions bundle if you're happy with the results\n")
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
        
        let previousScores = readPreviousScores()
        
        // Perform basic assertions on the first (completely untrained) and last (completely trained)
        // session. When the assertions pass, the app provides acceptable user experience
        var scores: [String: AnyObject] = [:]
        for (name, _, results) in evaluatedSessions {
            let firstResult = results.first!
            let lastResult = results.last!
            
            let firstLabelAccuracy = firstResult.labelsAccuracy(ignoring: [.Intensity])
            let firstWeightedLoss = firstResult.labelsWeightedLoss(.NumberOfTaps, ignoring: [.Intensity])
            let firstExerciseAccuracy = firstResult.exercisesAccuracy()
            let lastLabelAccuracy = lastResult.labelsAccuracy(ignoring: [.Intensity])
            let lastWeightedLoss = lastResult.labelsWeightedLoss(.NumberOfTaps, ignoring: [.Intensity])
            let lastExerciseAccuracy = lastResult.exercisesAccuracy()
            var sessionScores: [String:Double] = [:]
            if !firstLabelAccuracy.isNaN { sessionScores["FLA"] = firstLabelAccuracy }
            if !firstWeightedLoss.isNaN { sessionScores["FWL"] = firstWeightedLoss }
            if !firstExerciseAccuracy.isNaN { sessionScores["FEA"] = firstExerciseAccuracy }
            if !lastLabelAccuracy.isNaN { sessionScores["LLA"] = lastLabelAccuracy }
            if !lastWeightedLoss.isNaN { sessionScores["LWL"] = lastWeightedLoss }
            if !lastExerciseAccuracy.isNaN { sessionScores["LEA"] = lastExerciseAccuracy }
            scores[name] = sessionScores
            
            // The first session can be inaccurate, but must be acceptable for the users
            XCTAssertLessThanOrEqual(firstWeightedLoss, 2, name)
            XCTAssertGreaterThanOrEqual(firstLabelAccuracy, 0.5, name)
            XCTAssertGreaterThanOrEqual(firstExerciseAccuracy, 0.75, name)
            
            // The last session must be very accurate
            XCTAssertGreaterThanOrEqual(lastLabelAccuracy, 0.9, name)
            XCTAssertGreaterThanOrEqual(lastExerciseAccuracy, 0.92, name)
            XCTAssertLessThanOrEqual(lastWeightedLoss, 1, name)
            
            // Overall, the last result must be better than the first result
            XCTAssertGreaterThanOrEqual(lastLabelAccuracy, firstLabelAccuracy, name)
            XCTAssertGreaterThanOrEqual(lastExerciseAccuracy, firstExerciseAccuracy, name)
            XCTAssertLessThanOrEqual(lastWeightedLoss, firstWeightedLoss, name)
            
            // The prediction should be better than the previous one
            if let previousScores = previousScores[name] {
                
                /// truncate the values before comparing to avoids floating point issues
                func trunc(value: Double) -> Double { return round(value * 1000.0) / 1000.0 }
                
                if let score = previousScores["FLA"] { XCTAssertGreaterThanOrEqual(trunc(firstLabelAccuracy), trunc(score), name) }
                if let score = previousScores["FWL"] { XCTAssertLessThanOrEqual(trunc(firstWeightedLoss), trunc(score), name) }
                if let score = previousScores["FEA"] { XCTAssertGreaterThanOrEqual(trunc(firstExerciseAccuracy), trunc(score), name) }
                
                if let score = previousScores["LLA"] { XCTAssertGreaterThanOrEqual(trunc(lastLabelAccuracy), trunc(score), name) }
                if let score = previousScores["LWL"] { XCTAssertLessThanOrEqual(trunc(lastWeightedLoss), trunc(score), name) }
                if let score = previousScores["LEA"] { XCTAssertGreaterThanOrEqual(trunc(lastExerciseAccuracy), trunc(score), name) }
            }
        }
        
        print("\nEyball results\n")
        for (exerciseType, results) in (evaluatedSessions.groupBy { $0.1 }) {
            let last = results.last!
            print(last.0)
            print(last.2.last!.description)
            for i in 0..<count {
                let bla = project(results, index: i) { $0.labelsAccuracy(ignoring: [.Intensity]) }.maxElement()
                let bwl = project(results, index: i) { $0.labelsWeightedLoss(.RawValue, ignoring: [.Intensity]) }.minElement()
                let bea = project(results, index: i) { $0.exercisesAccuracy() }.maxElement()

                print("Best EA = \(bea)")
                print("Best LA = \(bla)")
                print("Best WL = \(bwl)")
                print("")
            }
        }
        
        writeTestScores(scores)
    }
    
}
