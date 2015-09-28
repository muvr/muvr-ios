import Foundation
import XCTest
@testable import MuvrKit

class MKSensorDataCodecTests : XCTestCase {
    
    func testEncodeDecode() {
        let d = try! MKSensorData(
            types: [.Accelerometer(location: .RightWrist), .Gyroscope(location: .RightWrist), .HeartRate],
            start: 0,
            samplesPerSecond: 1,
            samples: [Float](count: 700, repeatedValue: 0)
        )
        
        let encoded = try! d.encode()
        let dx = try! MKSensorData.decode(encoded)
        XCTAssertEqual(d, dx)
    }
    
}