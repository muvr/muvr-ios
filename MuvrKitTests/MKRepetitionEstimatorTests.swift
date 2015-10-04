import Foundation
import XCTest
@testable import MuvrKit

class MKRepetitionEstimatorTests : XCTestCase {

    func testSimpleSynthetic() {
        let block = MKSensorData.sensorData(types: [MKSensorDataType.Accelerometer(location: .LeftWrist)], samplesPerSecond: 100, generating: 400, withValue: .Sin1(period: 10))
        let (count, _) = try! MKRepetitionEstimator().estimate(data: block)
        XCTAssertEqual(count, 1)
    }
    
}
