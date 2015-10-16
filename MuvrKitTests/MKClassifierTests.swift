import Foundation
import XCTest
@testable import MuvrKit

class MKClassifierTests : XCTestCase {
    lazy var classifier: MKClassifier = {
        let data = NSData(contentsOfFile: NSBundle(forClass: MKClassifierTests.self).pathForResource("model-3", ofType: "raw")!)!
        let model = MKExerciseModel(layerConfig: [1200, 250, 100, 3], weights: data,
            sensorDataTypes: [.Accelerometer(location: .LeftWrist)],
            exerciseIds: ["1", "2", "3"])
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
    
    ///
    /// Tests that class 1 is correctly identified
    ///
    func testClassA() {
        let fileName = NSBundle(forClass: MuvrKitTests.self).pathForResource("class-1", ofType: "csv")!
        let block = try! MKSensorData.sensorData(types: [MKSensorDataType.Accelerometer(location: .LeftWrist)], samplesPerSecond: 100, loading: fileName)
        let cls = try! classifier.classify(block: block, maxResults: 100)
        XCTAssertEqual(cls.first!.exerciseId, "1")
        XCTAssertGreaterThan(cls.first!.confidence, 0.99)
    }

    ///
    /// Tests that class 1 is correctly identified
    ///
    func testClassAFromAppleWatch() {
        let fileName = NSBundle(forClass: MuvrKitTests.self).pathForResource("single-biceps-curl-1", ofType: "raw")!
        let block = try! MKSensorData(decoding: NSData(contentsOfFile: fileName)!)
        let cls = try! classifier.classify(block: block, maxResults: 100)
        XCTAssertEqual(cls.first!.exerciseId, "1")
        XCTAssertGreaterThan(cls.first!.confidence, 0.99)
    }

    ///
    /// Tests that all zeros does not classify the right value
    ///
    func testZeros() {
        let block = MKSensorData.sensorData(types: [MKSensorDataType.Accelerometer(location: .LeftWrist)], samplesPerSecond: 100, generating: 400, withValue: .Constant(value: 0))
        let cls = try! classifier.classify(block: block, maxResults: 100)
        XCTAssertLessThan(cls.first!.confidence, 0.5)
    }
    
    
}