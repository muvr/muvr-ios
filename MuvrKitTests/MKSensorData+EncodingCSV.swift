import Foundation
import XCTest
@testable import MuvrKit

class MKSensorDataEncodingCSVTests : XCTestCase {
    
    func testEncodeNoLabels() {
        let sd = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 1, samples: [Float](count: 6, repeatedValue: 0))
        let s = String(data: sd.encodeAsCsv(labelledExercises: []), encoding: NSASCIIStringEncoding)!
        XCTAssertEqual("0.0,0.0,0.0,,,,\n0.0,0.0,0.0,,,,\n", s)
    }
    
    func testEncodeWithLabels() {
        let sd = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 1, samples: [Float](count: 9, repeatedValue: 0))
        let bc = MKLabelledExercise(exerciseId: "bc", start: NSDate(timeIntervalSince1970: 0), end: NSDate(timeIntervalSince1970: 1), repetitions: 10, intensity: 0.8, weight: 8)
        let te = MKLabelledExercise(exerciseId: "te", start: NSDate(timeIntervalSince1970: 2), end: NSDate(timeIntervalSince1970: 3), repetitions: 10, intensity: 0.9, weight: 9)
        let s = String(data: sd.encodeAsCsv(labelledExercises: [bc, te]), encoding: NSASCIIStringEncoding)!
        XCTAssertEqual("0.0,0.0,0.0,bc,0.8,8.0,10,\n0.0,0.0,0.0,,,,\n0.0,0.0,0.0,te,0.9,9.0,10,\n", s)
    }
    
}
