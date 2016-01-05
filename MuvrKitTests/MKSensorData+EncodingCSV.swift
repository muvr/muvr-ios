import Foundation
import XCTest
@testable import MuvrKit

class MKSensorDataEncodingCSVTests : XCTestCase {
    
    func testEncodeNoLabels() {
        let sd = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 1, samples: [Float](count: 6, repeatedValue: 0))
        let s = String(data: sd.encodeAsCsv(labelledExercises: []), encoding: NSASCIIStringEncoding)!
        XCTAssertEqual("0.0,0.0,0.0,,,,\n0.0,0.0,0.0,,,,\n", s)
    }
    
    class SimpleMKLabelledExercise : NSObject, MKLabelledExercise {
        /// The exercise id—a classifier label, not localised
        var exerciseId: MKExerciseId
        /// The start date
        var start: NSDate
        /// The end date
        var duration: Double
        /// # repetitions; > 0
        var repetitionsLabel: Int32
        /// The intensity; (0..1.0)
        var intensityLabel: MKExerciseIntensity
        /// The weight in kg; > 0
        var weightLabel: Double
        /// The confidence
        var confidence: Double { get { return 1.0 } }
        
        init(exerciseId: String, start: NSDate, duration: Double, repetitions: Int32, intensity: MKExerciseIntensity, weight: Double) {
            self.exerciseId = exerciseId
            self.start = start
            self.duration = duration
            self.repetitionsLabel = repetitions
            self.intensityLabel = intensity
            self.weightLabel = weight
        }
        
    }
    
    func testEncodeWithLabels() {
        let sd = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 1, samples: [Float](count: 9, repeatedValue: 0))
        let bc = SimpleMKLabelledExercise(exerciseId: "bc", start: NSDate(timeIntervalSince1970: 0), duration: 1, repetitions: 10, intensity: 0.8, weight: 8)
        let te = SimpleMKLabelledExercise(exerciseId: "te", start: NSDate(timeIntervalSince1970: 2), duration: 1, repetitions: 10, intensity: 0.9, weight: 9)
        let s = String(data: sd.encodeAsCsv(labelledExercises: [bc, te]), encoding: NSASCIIStringEncoding)!
        XCTAssertEqual("0.0,0.0,0.0,bc,0.8,8.0,10\n0.0,0.0,0.0,,,,\n0.0,0.0,0.0,te,0.9,9.0,10\n", s)
    }
    
}
