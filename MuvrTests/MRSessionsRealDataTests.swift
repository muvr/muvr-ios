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

import CoreData

extension MRAppDelegate {
    
    ///
    /// Destroys and recreates the persistent store
    /// Makes sure every scenario runs on fresh data
    ///
    func cleanup() throws {
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("MuvrCoreData.sqlite")
        try persistentStoreCoordinator.destroyPersistentStoreAtURL(url, withType: NSSQLiteStoreType, options: nil)
        try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        
        // reset the current location
        let error = NSError(domain: "test", code: 0, userInfo: nil)
        locationManager(CLLocationManager(), didFailWithError: error)
        
        // load empty session plan
        self.loadSessionPlan()
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
    
    private typealias SessionName = String
    private typealias EvaluationResult = (SessionName, MKExerciseType, MRExerciseSessionEvaluator.Result, Bool)
    private typealias SessionScore = [Score]
    
    private enum Score {
        case ExerciseAccuracy(value: Double)
        case LabelAccuracy(value: Double)
        case WeightedLoss(value: Double)
        case SessionAccuracy(value: Double)
        
        var value: Double {
            switch self {
            case .ExerciseAccuracy(let v): return v
            case .LabelAccuracy(let v): return v
            case .WeightedLoss(let v): return v
            case .SessionAccuracy(let v): return v
            }
        }
        
        var truncValue: Double {
            let mult = 1000.0
            return round(self.value * mult) / mult
        }
        
        var name: String {
            switch self {
            case .ExerciseAccuracy: return "EA"
            case .LabelAccuracy: return "LA"
            case .WeightedLoss: return "WL"
            case .SessionAccuracy: return "SA"
            }
        }
        
        var description: String {
            switch self {
            case .ExerciseAccuracy: return "Exercise Accuracy"
            case .LabelAccuracy: return "Label Accuracy"
            case .WeightedLoss: return "Weighted Loss"
            case .SessionAccuracy: return "Session Accuracy"
            }
        }
        
        init?(name: String, value: Double) {
            switch name {
            case "EA": self = .ExerciseAccuracy(value: value)
            case "LA": self = .LabelAccuracy(value: value)
            case "WL": self = .WeightedLoss(value: value)
            case "SA": self = .SessionAccuracy(value: value)
            default: return nil
            }
        }
        
        func isBetterThan(other: Score, session: SessionName) -> Bool {
            let p = self.truncValue
            let e = other.truncValue
            switch (self) {
            case .ExerciseAccuracy:
                XCTAssertGreaterThanOrEqual(p, e, "Exercise accuracy for \(session)")
                return p >= e
            case .LabelAccuracy:
                XCTAssertGreaterThanOrEqual(p, e, "Label accuracy for \(session)")
                return p >= e
            case .WeightedLoss:
                XCTAssertLessThanOrEqual(p, e, "Weighted loss for \(session)")
                return p <= e
            case .SessionAccuracy:
                XCTAssertGreaterThanOrEqual(p, e, "Session accuracy for \(session)")
                return p >= e
            }
        }
    }
    
    var scenarios: [String] {
        let bundlePath = NSBundle(forClass: MRSessionsRealDataTests.self).pathForResource("Sessions", ofType: "bundle")!
        let bundle = NSBundle(path: bundlePath)!
        return bundle.pathsForResourcesOfType(nil, inDirectory: nil).filter {
            var isDirectory: ObjCBool = false
            NSFileManager.defaultManager().fileExistsAtPath($0, isDirectory: &isDirectory)
            return isDirectory.boolValue
        }.map {
            NSString(string: $0).lastPathComponent
        }
    }
    
    private func runScenario(app: MRAppDelegate, scenario: String) -> String {
        try! app.cleanup() // remove any existing data
        
        var text: String = "SCENARIO \(scenario)\n"
        // Load expected scores for this scenario
        var expectedScores = readExpectedScores(scenario)
        var sessions = 0 // number of sessions in the scenario
        var validSessions = 0 // number of sessions matching expected threshold
        var correctSessions = 0 // number of sessions types correctly predicted
        
        // Evaluate count sessions, giving the system the opportunity to learn the users
        // journey through the sessions
        let evaluatedSessions: [EvaluationResult] = readSessions(app.exerciseDetailForExerciseId, from: scenario).map { evalSession(app, loadedSession: $0) }
        
        // Check that each session in this scenario meet the expected criteria
        for (name, _, result, correctSession) in evaluatedSessions {
            sessions += 1
            if correctSession { correctSessions += 1 }
            
            // Compute session's score: accuracy, loss, ...
            var sessionScore: SessionScore = []
            if let value = result.labelsAccuracy(ignoring: [.Intensity]) { sessionScore.append(.LabelAccuracy(value: value)) }
            if let value = result.labelsWeightedLoss(.NumberOfTaps, ignoring: [.Intensity]) { sessionScore.append(.WeightedLoss(value: value)) }
            sessionScore.append(.ExerciseAccuracy(value: result.exercisesAccuracy()))
            
            // The session should meet the expected score
            if let expectedScore = expectedScores[name] {
                text.appendContentsOf("\nSession \(name)\n")
                let passed = sessionScore.reduce(true) { res, score in
                    let exp = expectedScore.filter { $0.name == score.name }.first
                    guard let expected = exp else { return res }
                    let isBetter = score.isBetterThan(expected, session: name)
                    text.appendContentsOf("   \(isBetter ? "✓" : "✗") \(score.description): \(expected.truncValue) -> \(score.truncValue)\n")
                    return res && isBetter
                }
                
                if passed {
                    validSessions += 1
                    expectedScores[name] = sessionScore
                }
            }
        }
        let score: Score = .SessionAccuracy(value: Double(correctSessions) / Double(sessions))
        if let expectedScore = expectedScores[scenario] {
            let exp = expectedScore.filter { $0.name == score.name }.first
            if let expected = exp {
                let isBetter = score.isBetterThan(expected, session: scenario)
                text.appendContentsOf("\n\(isBetter ? "✓" : "✗") \(score.description): \(expected.truncValue) -> \(score.truncValue)\n")
            }
        }
        text.appendContentsOf("\nDone SCENARIO \(scenario) with \(validSessions)/\(sessions) valid sessions\n")
        
        return text
    }
    
    private func readSessions(detail: MKExercise.Id -> MKExerciseDetail?, from directory: String) -> [MRLoadedSession] {
        let bundlePath = NSBundle(forClass: MRSessionsRealDataTests.self).pathForResource("Sessions", ofType: "bundle")!
        let bundle = NSBundle(path: bundlePath)!
        return bundle.pathsForResourcesOfType("csv", inDirectory: directory).sort().map { path in
            return MRSessionLoader.read(path, detail: detail)
        }
    }
    
    private func evalSession(app: MRAppDelegate, loadedSession: MRLoadedSession) -> EvaluationResult {
        let name = "\(loadedSession.description) \(loadedSession.exerciseType)"
        print("\nEvaluating session \(loadedSession.description)")
        
        var correctSession = false
        if let s = app.sessionTypes.first {
            correctSession = s.exerciseType == loadedSession.exerciseType
            print("Predicted session: \(s.exerciseType) \(correctSession ? "and": "but") was \(loadedSession.exerciseType)")
        } else {
            print("Predicted session: nothing but was \(loadedSession.exerciseType)")
        }
        try! app.startSession(.AdHoc(exerciseType: loadedSession.exerciseType))
        let result = MRExerciseSessionEvaluator(loadedSession: loadedSession).evaluate(app.currentSession!)
        try! app.endCurrentSession()
        
        return (name, loadedSession.exerciseType, result, correctSession)
    }
    
    private func readExpectedScores(directory: String) -> [SessionName: SessionScore] {
        let bundlePath = NSBundle(forClass: MRSessionsRealDataTests.self).pathForResource("Sessions", ofType: "bundle")!
        let bundle = NSBundle(path: bundlePath)!
        let fileName = bundle.pathsForResourcesOfType("json", inDirectory: directory).first! // assume one json file per directory
        let json = try! NSJSONSerialization.JSONObjectWithData(NSData(contentsOfFile: fileName)!, options: .AllowFragments)
        var dict: [SessionName: SessionScore] = [:]
        (json as! [String: [String: Double]]).forEach { name, scores in
            dict[name] = scores.flatMap { Score(name: $0, value: $1) }
        }
        return dict
    }
    
    func testTimeless() {
        let app = UIApplication.sharedApplication().delegate as! MRAppDelegate
        // At Kingfisher
        // let kingfisher = CLLocation(latitude: 53.435739, longitude: -2.165993)
        // app.locationManager(CLLocationManager(), didUpdateLocations: [kingfisher])
        
        // Run all scenarios
        scenarios.map { runScenario(app, scenario: $0) }.forEach { print($0) }
    }
    
}
