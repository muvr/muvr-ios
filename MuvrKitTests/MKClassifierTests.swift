import Foundation
import XCTest
@testable import MuvrKit

class MKClassifierTests : XCTestCase {
    lazy var classifier: MKClassifier = {
        let data = NSData(contentsOfFile: NSBundle(forClass: MKClassifierTests.self).pathForResource("test-model", ofType: "raw")!)!
        let model = MKExerciseModel(layerConfig: [1200, 250, 100, 3], weights: data,
            sensorDataTypes: [.Accelerometer(location: .LeftWrist)],
            exerciseIds: ["a", "b", "c"])
        return MKClassifier(model: model)
    }()
    
    /// 
    /// Tests that the classification rejects insufficient data
    ///
    func testClassifyNoSensorDataType() {
        do {
            try classifier.classify(block: MKSensorData(types: [.HeartRate], start: 0, samplesPerSecond: 1, samples: []), maxResults: 100)
            XCTFail("No exception")
        } catch MKClassifierError.NoSensorDataType(_) {
        } catch {
            XCTFail("Bad exception")
        }
    }
    
    ///
    /// Tests that the classification rejects insufficient data
    ///
    func testClassifyNotEnoughData() {
        do {
            try classifier.classify(block: MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 1, samples: [1,2,3]), maxResults: 100)
            XCTFail("No exception")
        } catch MKClassifierError.NotEnoughRows(_) {
        } catch {
            XCTFail("Bad exception")
        }
    }
    
    
    
}