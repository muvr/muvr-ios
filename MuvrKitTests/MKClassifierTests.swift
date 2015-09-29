import Foundation
import XCTest
@testable import MuvrKit

class MKClassifierTests : XCTestCase {
    lazy var classifier: MKClassifier = {
        let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("test-model", ofType: "raw")!)!
        let model = MKExerciseModel(layerConfig: [], weights: data,
            sensorDataTypes: [.Accelerometer(location: .LeftWrist)],
            exerciseIds: ["a", "b", "c"])
        return MKClassifier(model: model)
    }()
    
    /// 
    /// Tests that the classification rejects insufficient data
    ///
    func testClassifyNotEnoughData() {
        do {
            try classifier.classify(block: MKSensorData(types: [.HeartRate], start: 0, samplesPerSecond: 1, samples: []), maxResults: 100)
            XCTFail("No exception")
        } catch MKClassifierError.NoSensorDataType(_) {
        } catch {
            XCTFail("Bad exception")
        }
    }
    
}