import Foundation
import XCTest
@testable import MuvrKit

class MKSessionClassifierTests : XCTestCase, MKExerciseModelSource, MKClassificationHintSource {
 
    ///
    /// Implementation of the ``MKSessionClassifierDelegate`` that fires the matching ``XCTestExpectation``s
    /// so that the test can be executed asynchronously.
    ///
    class Delegate : MKSessionClassifierDelegate {
        var endExerciseTrigger: MKSessionClassifierDelegateEndTrigger?
        var startExerciseTrigger: MKSessionClassifierDelegateStartTrigger?
        
        private let startExerciseExpectation: XCTestExpectation?
        private let endExerciseExpectation: XCTestExpectation?
        private let startExpectation: XCTestExpectation?
        private let endExpectation: XCTestExpectation?
        
        init(startExpectation: XCTestExpectation?, endExpectation: XCTestExpectation?,
             startExerciseExpectation: XCTestExpectation?, endExerciseExpectation: XCTestExpectation?) {
            self.startExpectation = startExpectation
            self.endExpectation = endExpectation
            self.startExerciseExpectation = startExerciseExpectation
            self.endExerciseExpectation = endExerciseExpectation
        }
        
        func sessionClassifierDidStartSession(session: MKExerciseSession) {
            startExpectation?.fulfill()
        }
        
        func sessionClassifierDidEndSession(session: MKExerciseSession, sensorData: MKSensorData?) {
            endExpectation?.fulfill()
        }
        
        func sessionClassifierDidEndExercise(session: MKExerciseSession, trigger: MKSessionClassifierDelegateEndTrigger) -> MKExerciseSession.State? {
            endExerciseExpectation?.fulfill()
            endExerciseTrigger = trigger
            return .NotExercising
        }
        
        func sessionClassifierDidStartExercise(session: MKExerciseSession, trigger: MKSessionClassifierDelegateStartTrigger) -> MKExerciseSession.State? {
            startExerciseExpectation?.fulfill()
            startExerciseTrigger = trigger
            return .Exercising(exerciseId: "")
        }
        
        func sessionClassifierDidSetupExercise(session: MKExerciseSession, trigger: MKSessionClassifierDelegateStartTrigger) -> MKExerciseSession.State? {
            if case .SetupDetected(let ep) = trigger where !ep.isEmpty {
                return MKExerciseSession.State.Exercising(exerciseId: ep.first!.0)
            }
            return nil
        }
        
        func repsCountFeed(session: MKExerciseSession, reps: Int, start: NSDate, end: NSDate) {
            
        }
        
    }
    
    let classificationHints: [MKClassificationHint]? = nil
    
    func exerciseModelForExerciseSetup() throws -> MKExerciseModel {
        return try exerciseModelForExerciseType(MKExerciseType.ResistanceTargeted(muscleGroups: [.Arms]))
    }
    
    func exerciseModelForExerciseType(exerciseType: MKExerciseType) throws -> MKExerciseModel {
        let modelPath = NSBundle(forClass: MKClassifierTests.self).pathForResource("model-3", ofType: "raw")!
        let weights = MKExerciseModel.loadWeightsFromFile(modelPath)
        let model = MKExerciseModel(
            layerConfiguration: try! MKLayerConfiguration.parse(text: "1200 id 250 relu 100 relu 3 logistic"),
            weights: weights,
            sensorDataTypes: [.Accelerometer(location: .LeftWrist)],
            labels: [("1", .ResistanceWholeBody), ("2", .ResistanceWholeBody), ("3", .ResistanceWholeBody)],
            minimumDuration: 0)
        
        return model
    }
        
    ///
    /// Tests that the simple flow of start -> one block of sensor data -> end works as expected, namely that:
    /// - classification triggers some time after receiving sensor data
    /// - summary triggers some time after ending the session
    ///
    func testSimpleSessionFlow() {
        let se = expectationWithDescription("start")
        let ee = expectationWithDescription("end")
        
        let delegate = Delegate(startExpectation: se, endExpectation: ee, startExerciseExpectation: nil, endExerciseExpectation: nil)
        let splitter = MKSensorDataSplitter(exerciseModelSource: self, hintSource: self)
        let classifier = MKSessionClassifier(exerciseModelSource: self, sensorDataSplitter: splitter, delegate: delegate)
        let sd = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 50, samples: [Float](count: 1200, repeatedValue: 0.3))
        let session = MKExerciseConnectivitySession(id: "1234", start: NSDate(), end: nil, last: false, exerciseType: .ResistanceWholeBody)

        classifier.exerciseConnectivitySessionDidStart(session: session)
        classifier.sensorDataConnectivityDidReceiveSensorData(accumulated: sd, new: sd, session: session)
        classifier.exerciseConnectivitySessionDidEnd(session: session.withData(sd))
        
        waitForExpectationsWithTimeout(10) { err in
            // TODO: add assertions here
        }
    }
    
    ///
    /// Tests that user motion is detected
    ///
    func testMotionDetection() {
        let see = expectationWithDescription("start-exercise")
        let eee = expectationWithDescription("end-exercise")
        
        var samples = [Float](count: 1200, repeatedValue: 0.3)
        for i in 0..<samples.count/2 {
            samples[2 * i] *= -1
        }
        let movement   = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 50, samples: samples)
        let noMovement = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 50, samples: [Float](count: 1200, repeatedValue: 0.3))
        var session = MKExerciseConnectivitySession(id: "1234", start: NSDate(), end: nil, last: false, exerciseType: .ResistanceWholeBody)
        session.realStart = NSDate()
        
        let delegate = Delegate(startExpectation: nil, endExpectation: nil, startExerciseExpectation: see, endExerciseExpectation: eee)
        let splitter = MKSensorDataSplitter(exerciseModelSource: self, hintSource: self)
        let classifier = MKSessionClassifier(exerciseModelSource: self, sensorDataSplitter: splitter, delegate: delegate)
        classifier.exerciseConnectivitySessionDidStart(session: session)
        classifier.sensorDataConnectivityDidReceiveSensorData(accumulated: movement, new: movement, session: session)
        classifier.sensorDataConnectivityDidReceiveSensorData(accumulated: movement, new: movement, session: session)
        classifier.sensorDataConnectivityDidReceiveSensorData(accumulated: movement, new: noMovement, session: session)
        classifier.exerciseConnectivitySessionDidEnd(session: session.withData(movement))
        
        waitForExpectationsWithTimeout(10) { err in
            XCTAssertEqual(delegate.startExerciseTrigger!, MKSessionClassifierDelegateStartTrigger.MotionDetected)
            XCTAssertEqual(delegate.endExerciseTrigger!, MKSessionClassifierDelegateEndTrigger.NoMotionDetected)
        }
    }
    
    
}
