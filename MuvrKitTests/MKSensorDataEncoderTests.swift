import Foundation
import XCTest
@testable import MuvrKit

class MKSensorDataEncoderTest : XCTestCase {
    private let sample = [Float(0.5), Float(0.5), Float(0.5)]

    private func dataEncoder(startDate: NSDate) -> (MKSensorDataEncoder, NSMutableData) {
        let sensor = MKSensorDataType.Accelerometer(location: MKSensorDataType.Location.LeftWrist)
        let data = NSMutableData()
        let target = MKMutableDataEncoderTarget(data: data)
        let encoder = MKSensorDataEncoder(target: target, types: [sensor], samplesPerSecond: 50)
        return (encoder, data)
    }
    
    func testAppendSample() {
        let start = NSDate(timeIntervalSinceNow: -60)
        let (encoder, data) = dataEncoder(start)
        for i in 0..<100 {
            encoder.append(sample, sampleDate: NSDate(timeInterval: 0.02 * Double(i), sinceDate: start))
        }
        encoder.close()
        XCTAssertEqual(data.length, 300 * sizeof(Float) + 20)
    }
    
    func testAppendTooManySamples() {
        let start = NSDate(timeIntervalSinceNow: -60)
        let (encoder, data) = dataEncoder(start)
        for i in 0..<199 {
            encoder.append(sample, sampleDate: NSDate(timeInterval: 0.01 * Double(i), sinceDate: start))
        }
        encoder.close()
        NSLog("\(encoder.duration!)")
        XCTAssertEqual(data.length, 300 * sizeof(Float) + 20)
    }
    
    func testAppendWithMissingSamples() {
        let start = NSDate(timeIntervalSinceNow: -60)
        let (encoder, data) = dataEncoder(start)
        for i in 0..<50 {
            encoder.append(sample, sampleDate: NSDate(timeInterval: 0.02 * Double(i), sinceDate: start))
        }
        encoder.close()
        XCTAssertEqual(data.length, 150 * sizeof(Float) + 20)
        encoder.append(sample, sampleDate: NSDate(timeInterval: 1.0, sinceDate: start))
        encoder.append(sample, sampleDate: NSDate(timeInterval: 2.0, sinceDate: start))
        encoder.close()
        XCTAssertEqual(data.length, 303 * sizeof(Float) + 20) // 101 samples (including samples at time 0.0 and time 2.0)
    }
    
    
}
