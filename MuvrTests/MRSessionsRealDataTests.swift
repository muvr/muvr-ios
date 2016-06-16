import Foundation
import XCTest
import CoreLocation
@testable import Muvr
@testable import MuvrKit

extension Array {
    
    func groupBy<A : Hashable>(_ f: (Element) -> A) -> [A : [Element]] {
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
        let url = try! self.applicationDocumentsDirectory.appendingPathComponent("MuvrCoreData.sqlite")
        try persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
        try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        
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
        case exerciseAccuracy(value: Double)
        case labelAccuracy(value: Double)
        case weightedLoss(value: Double)
        case sessionAccuracy(value: Double)
        
        var value: Double {
            switch self {
            case .exerciseAccuracy(let v): return v
            case .labelAccuracy(let v): return v
            case .weightedLoss(let v): return v
            case .sessionAccuracy(let v): return v
            }
        }
        
        var truncValue: Double {
            let mult = 1000.0
            return round(self.value * mult) / mult
        }
        
        var name: String {
            switch self {
            case .exerciseAccuracy: return "EA"
            case .labelAccuracy: return "LA"
            case .weightedLoss: return "WL"
            case .sessionAccuracy: return "SA"
            }
        }
        
        var description: String {
            switch self {
            case .exerciseAccuracy: return "Exercise Accuracy"
            case .labelAccuracy: return "Label Accuracy"
            case .weightedLoss: return "Weighted Loss"
            case .sessionAccuracy: return "Session Accuracy"
            }
        }
        
        init?(name: String, value: Double) {
            switch name {
            case "EA": self = .exerciseAccuracy(value: value)
            case "LA": self = .labelAccuracy(value: value)
            case "WL": self = .weightedLoss(value: value)
            case "SA": self = .sessionAccuracy(value: value)
            default: return nil
            }
        }
        
        func isBetterThan(_ other: Score, session: SessionName) -> Bool {
            let p = self.truncValue
            let e = other.truncValue
            switch (self) {
            case .exerciseAccuracy:
                XCTAssertGreaterThanOrEqual(p, e, "Exercise accuracy for \(session)")
                return p >= e
            case .labelAccuracy:
                XCTAssertGreaterThanOrEqual(p, e, "Label accuracy for \(session)")
                return p >= e
            case .weightedLoss:
                XCTAssertLessThanOrEqual(p, e, "Weighted loss for \(session)")
                return p <= e
            case .sessionAccuracy:
                XCTAssertGreaterThanOrEqual(p, e, "Session accuracy for \(session)")
                return p >= e
            }
        }
    }
    
    var scenarios: [String] {
        let bundlePath = Bundle(for: MRSessionsRealDataTests.self).pathForResource("Sessions", ofType: "bundle")!
        let bundle = Bundle(path: bundlePath)!
        return bundle.pathsForResources(ofType: nil, inDirectory: nil).filter {
            var isDirectory: ObjCBool = false
            FileManager.default().fileExists(atPath: $0, isDirectory: &isDirectory)
            return isDirectory.boolValue
        }.map {
            NSString(string: $0).lastPathComponent
        }
    }
    
    private func runScenario(_ app: MRAppDelegate, scenario: String) -> String {
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
            if let value = result.labelsAccuracy(ignoring: [.intensity]) { sessionScore.append(.labelAccuracy(value: value)) }
            if let value = result.labelsWeightedLoss(.numberOfTaps, ignoring: [.intensity]) { sessionScore.append(.weightedLoss(value: value)) }
            sessionScore.append(.exerciseAccuracy(value: result.exercisesAccuracy()))
            
            // The session should meet the expected score
            if let expectedScore = expectedScores[name] {
                text.append("\nSession \(name)\n")
                let passed = sessionScore.reduce(true) { res, score in
                    let exp = expectedScore.filter { $0.name == score.name }.first
                    guard let expected = exp else { return res }
                    let isBetter = score.isBetterThan(expected, session: name)
                    text.append("   \(isBetter ? "✓" : "✗") \(score.description): \(expected.truncValue) -> \(score.truncValue)\n")
                    return res && isBetter
                }
                
                if passed {
                    validSessions += 1
                    expectedScores[name] = sessionScore
                }
            }
        }
        let score: Score = .sessionAccuracy(value: Double(correctSessions) / Double(sessions))
        if let expectedScore = expectedScores[scenario] {
            let exp = expectedScore.filter { $0.name == score.name }.first
            if let expected = exp {
                let isBetter = score.isBetterThan(expected, session: scenario)
                text.append("\n\(isBetter ? "✓" : "✗") \(score.description): \(expected.truncValue) -> \(score.truncValue)\n")
            }
        }
        text.append("\nDone SCENARIO \(scenario) with \(validSessions)/\(sessions) valid sessions\n")
        
        return text
    }
    
    private func readSessions(_ detail: (MKExercise.Id) -> MKExerciseDetail?, from directory: String) -> [MRLoadedSession] {
        let bundlePath = Bundle(for: MRSessionsRealDataTests.self).pathForResource("Sessions", ofType: "bundle")!
        let bundle = Bundle(path: bundlePath)!
        return bundle.pathsForResources(ofType: "csv", inDirectory: directory).sorted().map { path in
            return MRSessionLoader.read(path, detail: detail)
        }
    }
    
    private func evalSession(_ app: MRAppDelegate, loadedSession: MRLoadedSession) -> EvaluationResult {
        let name = "\(loadedSession.description) \(loadedSession.exerciseType)"
        print("\nEvaluating session \(loadedSession.description)")
        
        var correctSession = false
        if let s = app.sessionTypes.first {
            correctSession = s.exerciseType == loadedSession.exerciseType
            print("Predicted session: \(s.exerciseType) \(correctSession ? "and": "but") was \(loadedSession.exerciseType)")
        } else {
            print("Predicted session: nothing but was \(loadedSession.exerciseType)")
        }
        try! app.startSession(.adHoc(exerciseType: loadedSession.exerciseType))
        let result = MRExerciseSessionEvaluator(loadedSession: loadedSession).evaluate(app.currentSession!)
        try! app.endCurrentSession()
        
        return (name, loadedSession.exerciseType, result, correctSession)
    }
    
    private func readExpectedScores(_ directory: String) -> [SessionName: SessionScore] {
        let bundlePath = Bundle(for: MRSessionsRealDataTests.self).pathForResource("Sessions", ofType: "bundle")!
        let bundle = Bundle(path: bundlePath)!
        let fileName = bundle.pathsForResources(ofType: "json", inDirectory: directory).first! // assume one json file per directory
        let json = try! JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: fileName)), options: .allowFragments)
        var dict: [SessionName: SessionScore] = [:]
        (json as! [String: [String: Double]]).forEach { name, scores in
            dict[name] = scores.flatMap { Score(name: $0, value: $1) }
        }
        return dict
    }
    
    func testTimeless() {
        let app = UIApplication.shared().delegate as! MRAppDelegate
        // At Kingfisher
        // let kingfisher = CLLocation(latitude: 53.435739, longitude: -2.165993)
        // app.locationManager(CLLocationManager(), didUpdateLocations: [kingfisher])
        
        // Run all scenarios
        scenarios.map { runScenario(app, scenario: $0) }.forEach { print($0) }
    }
    
}
