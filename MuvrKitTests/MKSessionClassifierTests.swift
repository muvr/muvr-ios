import Foundation
import XCTest
@testable import MuvrKit

class MKSessionClassifierTests : XCTestCase, MKExerciseModelSource {
 
    ///
    /// Implementation of the ``MKSessionClassifierDelegate`` that fires the matching ``XCTestExpectation``s
    /// so that the test can be executed asynchronously.
    ///
    class Delegate : MKSessionClassifierDelegate {
        var classified: MKExerciseSession?
        var ended: MKExerciseSession?
        var started: MKExerciseSession?
        var summarised: MKExerciseSession?
        
        private let summariseExpectation: XCTestExpectation
        private let classifyExpectation: XCTestExpectation
        
        ///
        /// Initialises this instance, assigning the ``classifyExpectation`` and ``summariseExpectation``.
        ///
        init(onClassify classifyExpectation: XCTestExpectation, onSummarise summariseExpectation: XCTestExpectation) {
            self.classifyExpectation = classifyExpectation
            self.summariseExpectation = summariseExpectation
        }
        
        func sessionClassifierDidClassify(session: MKExerciseSession) {
            self.classified = session
            self.classifyExpectation.fulfill()
        }
        
        func sessionClassifierDidEnd(session: MKExerciseSession) {
            self.ended = session
        }
        
        func sessionClassifierDidStart(session: MKExerciseSession) {
            self.started = session
        }
        
        func sessionClassifierDidSummarise(session: MKExerciseSession) {
            self.summarised = session
            self.summariseExpectation.fulfill()
        }
        
    }
    
    func getExerciseModel(id id: MKExerciseModelId) -> MKExerciseModel {
        let data = NSData(contentsOfFile: NSBundle(forClass: MKClassifierTests.self).pathForResource("model-3", ofType: "raw")!)!
        let model = MKExerciseModel(layerConfig: [1200, 250, 100, 3], weights: data,
            sensorDataTypes: [.Accelerometer(location: .LeftWrist)],
            exerciseIds: ["1", "2", "3"],
            minimumDuration: 0)

        return model
    }
    
    ///
    /// Tests that the simple flow of start -> one block of sensor data -> end works as expected, namely that:
    /// - classification triggers some time after receiving sensor data
    /// - summary triggers some time after ending the session
    ///
    func testSimpleSessionFlow() {
        let classifyExpectation = expectationWithDescription("classify")
        let summariseExpectation = expectationWithDescription("summarise")
        
        let delegate = Delegate(onClassify: classifyExpectation, onSummarise: summariseExpectation)
        let classifier = MKSessionClassifier(exerciseModelSource: self, delegate: delegate)
        let sd = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 50, samples: [Float](count: 1200, repeatedValue: 0.3))
        let session = MKExerciseConnectivitySession(id: "1234", exerciseModelId: "arms", startDate: NSDate())

        classifier.exerciseConnectivitySessionDidStart(session: session)
        classifier.sensorDataConnectivityDidReceiveSensorData(accumulated: sd, new: sd, session: session)
        classifier.exerciseConnectivitySessionDidEnd(session: session.withData(sd))
        
        waitForExpectationsWithTimeout(10) { err in
            // TODO: add assertions here
        }
    }
    
}
