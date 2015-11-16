import Foundation
import XCTest
@testable import MuvrKit

class MKSensorDataEncoderTest : XCTestCase {
    
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
            let v = Float(0.5)
            encoder.append([v, v, v], sampleDate: NSDate(timeInterval: 0.02 * Double(i), sinceDate: start))
        }
        encoder.close()
        XCTAssertEqual(data.length, 300 * sizeof(Float) + 20)
    }
    
    func testAppendTooManySamples() {
        let start = NSDate(timeIntervalSinceNow: -60)
        let (encoder, data) = dataEncoder(start)
        for i in 0...99 {
            let v = Float(i) / 100
            encoder.append([v, v, v], sampleDate: NSDate(timeInterval: 0.01 * Double(i), sinceDate: start))
        }
        encoder.close()
        XCTAssertEqual(data.length, 153 * sizeof(Float) + 20)
    }
    
    func testAppendWithMissingSamples() {
        let start = NSDate(timeIntervalSinceNow: -60)
        let (encoder, data) = dataEncoder(start)
        for i in 0...10 {
            let v = Float(i) / 10
            encoder.append([v, v, v], sampleDate: NSDate(timeInterval: 0.02 * Double(i), sinceDate: start))
        }
        encoder.close()
        XCTAssertEqual(data.length, 33 * sizeof(Float) + 20)
        encoder.append([10,10,10], sampleDate: NSDate(timeInterval: 0.4, sinceDate: start))
        encoder.close()
        XCTAssertEqual(data.length, 60 * sizeof(Float) + 20)
    }
    
    
}
