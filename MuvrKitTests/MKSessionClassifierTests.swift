import Foundation
import XCTest
@testable import MuvrKit

class MKSessionClassifierTests : XCTestCase, MKExerciseModelSource, MKClassificationHintSource {
 
    ///
    /// Implementation of the ``MKSessionClassifierDelegate`` that fires the matching ``XCTestExpectation``s
    /// so that the test can be executed asynchronously.
    ///
    class Delegate : MKSessionClassifierDelegate {
        var classified: MKExerciseSession?
        var ended: MKExerciseSession?
        var started: MKExerciseSession?
        
        private let classifyExpectation: XCTestExpectation
        
        ///
        /// Initialises this instance, assigning the ``classifyExpectation`` and ``summariseExpectation``.
        ///
        init(onClassify classifyExpectation: XCTestExpectation) {
            self.classifyExpectation = classifyExpectation
        }
        
        func sessionClassifierDidStart(session: MKExerciseSession) {
            self.started = session
        }

        func sessionClassifierDidClassify(session: MKExerciseSession, classified: [MKExerciseWithLabels], sensorData: MKSensorData) {
            self.classified = session
            self.classifyExpectation.fulfill()
        }
        
        func sessionClassifierDidEnd(session: MKExerciseSession, sensorData: MKSensorData?) {
            self.ended = session
        }
        
        func sessionClassifierDidEstimate(session: MKExerciseSession, estimated: [MKExerciseWithLabels]) {
            // noop
        }
    }
    
    let classificationHints: [MKClassificationHint]? = nil
    
    func exerciseModelForExerciseType(exerciseType: MKExerciseType) throws -> MKExerciseModel {
        let modelPath = NSBundle(forClass: MKClassifierTests.self).pathForResource("model-3", ofType: "raw")!
        let weights = MKExerciseModel.loadWeightsFromFile(modelPath)
        let model = MKExerciseModel(
            layerConfiguration: try! MKLayerConfiguration.parse(text: "1200 id 250 relu 100 relu 3 logistic"),
            weights: weights,
            sensorDataTypes: [.Accelerometer(location: .LeftWrist, dataFormat: .Float32)],
            labels: [("1", .ResistanceWholeBody), ("2", .ResistanceWholeBody), ("3", .ResistanceWholeBody)],
            minimumDuration: 0)
        
        return model
    }
    
    
    ///
    /// Not used
    /// Returns the same model as `exerciseModelForExerciseType`
    ///
    func activityModel() throws -> MKExerciseModel {
        return try exerciseModelForExerciseType(.GenericExercise)
    }
        
    ///
    /// Tests that the simple flow of start -> one block of sensor data -> end works as expected, namely that:
    /// - classification triggers some time after receiving sensor data
    /// - summary triggers some time after ending the session
    ///
    func testSimpleSessionFlow() {
        let classifyExpectation = expectationWithDescription("classify")
        
        let delegate = Delegate(onClassify: classifyExpectation)
        let splitter = MKSensorDataSplitter(exerciseModelSource: self, hintSource: self)
        let classifier = MKSessionClassifier(exerciseModelSource: self, sensorDataSplitter: splitter, delegate: delegate)
        let sd = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist, dataFormat: .Float32)], start: 0, samplesPerSecond: 50, samples: [Float](count: 1200, repeatedValue: 0.3))
        let session = MKExerciseConnectivitySession(id: "1234", start: NSDate(), end: nil, last: true, exerciseType: .ResistanceWholeBody)

        classifier.exerciseConnectivitySessionDidStart(session: session)
        classifier.sensorDataConnectivityDidReceiveSensorData(accumulated: sd, new: sd, session: session)
        classifier.exerciseConnectivitySessionDidEnd(session: session.withData(sd))
        
        waitForExpectationsWithTimeout(10) { err in
            // TODO: add assertions here
        }
    }
    
}
