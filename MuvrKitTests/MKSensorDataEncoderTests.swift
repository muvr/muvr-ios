import Foundation
import XCTest
@testable import MuvrKit

class MKSensorDataEncoderTest : XCTestCase {
    
    private func DataEncoder(startDate: NSDate) -> (MKSensorDataEncoder, NSMutableData) {
        let sensor = MKSensorDataType.Accelerometer(location: MKSensorDataType.Location.LeftWrist)
        let data = NSMutableData()
        let target = MKMutableDataEncoderTarget(data: data)
        let encoder = MKSensorDataEncoder(target: target, types: [sensor], samplesPerSecond: 50, startDate: startDate)
        return (encoder, data)
    }
    
    private func checkSampleCount(data: NSMutableData, samples: Int) {
        assert(data.length == samples * sizeof(Float) + 20) // add 20 bytes for header data
    }
    
    func testAppendSample() {
        let start = NSDate(timeIntervalSinceNow: -60)
        let (encoder, data) = DataEncoder(start)
        for i in 0...999 {
            let v = Float(i) / 1000
            encoder.append([v, v, v], date: NSDate(timeInterval: 0.02 * Double(i), sinceDate: start))
        }
        checkSampleCount(data, samples: 3000)
    }
    
    func testAppendTooManySamples() {
        let start = NSDate(timeIntervalSinceNow: -60)
        let (encoder, data) = DataEncoder(start)
        for i in 0...99 {
            let v = Float(i) / 100
            encoder.append([v, v, v], date: NSDate(timeInterval: 0.01 * Double(i), sinceDate: start))
        }
        checkSampleCount(data, samples: 153)
    }
    
    func testAppendWithMissingSamples() {
        let start = NSDate(timeIntervalSinceNow: -60)
        let (encoder, data) = DataEncoder(start)
        for i in 0...10 {
            let v = Float(i) / 10
            encoder.append([v, v, v], date: NSDate(timeInterval: 0.02 * Double(i), sinceDate: start))
        }
        checkSampleCount(data, samples: 33)
        encoder.append([10,10,10], date: NSDate(timeInterval: 0.4, sinceDate: start))
        checkSampleCount(data, samples: 60)
    }
    
    
}
