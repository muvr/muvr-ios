import Foundation
import XCTest
@testable import MuvrKit

class MKSensorDataThreedDTests : XCTestCase {
    let threeD = try! MKSensorData(dimension: 3, start: 0, samplesPerSecond: 1, samples: [-100, 0, 100])
    
    func testSamplesAsTriples() {
        let threeD = try! MKSensorData(dimension: 3, start: 0, samplesPerSecond: 1, samples: [-100, 0, 100, -90, 10, 110, -110, -10, 90])
        XCTAssertEqual(try! threeD.samplesAsTriples(), [
            MKSensorData.Triple(x: -100, y: 0,   z: 100),
            MKSensorData.Triple(x: -90,  y: 10,  z: 110),
            MKSensorData.Triple(x: -110, y: -10, z: 90),
        ])
    }
    
    /// ```
    ///   S1
    /// +  0
    /// ====
    ///   S1
    /// ```
    func testThreedDAppendEmpty() {
        var d = threeD
        try! d.append(MKSensorData(dimension: 3, start: 0, samplesPerSecond: 1, samples: [0, 0, 0]))
        XCTAssertEqual(d.end, 1)
        XCTAssertEqual(try! d.samplesAsTriples().first!, MKSensorData.Triple(x: 0, y: 0, z: 0))
    }
    
    /// ```
    ///   S1
    /// + S2
    /// ====
    ///   S2
    /// ```
    func testOneDAppendCompletelyOverlapping() {
        var d = threeD
        try! d.append(threeD)
        XCTAssertEqual(d.end, 1)
        XCTAssertEqual(try! d.samplesAsTriples().first!, MKSensorData.Triple(x: -100, y: 0, z: 100))
    }
    
    /// ```
    ///   S1
    /// +   S2
    /// ======
    ///   S1S2
    /// ```
    func testOneDAppendImmediatelyFollowing() {
        var d = threeD
        try! d.append(MKSensorData(dimension: 3, start: 1, samplesPerSecond: 1, samples: [-50, 50, 150]))
        try! d.append(MKSensorData(dimension: 3, start: 2, samplesPerSecond: 1, samples: [0, 100, 200]))
        XCTAssertEqual(d.end, 3)
        let x = try! d.samplesAsTriples()
        XCTAssertEqual(x, [
            MKSensorData.Triple(x: -100, y: 0,   z: 100),
            MKSensorData.Triple(x: -50,  y: 50,  z: 150),
            MKSensorData.Triple(x: 0,    y: 100, z: 200),
        ])
    }
    
    /// ```
    ///  S1
    /// +  .g.S2
    /// +       ·g·S3
    /// =============
    ///  S1...S2···S3
    /// ```
    func testOneDAppendAllowableGap() {
        var d = threeD
        try! d.append(MKSensorData(dimension: 3, start: 2, samplesPerSecond: 1, samples: [100, 100, 200]))
        XCTAssertEqual(d.end, 3)
        let x = try! d.samplesAsTriples()
        XCTAssertEqual(x, [
            MKSensorData.Triple(x: -100, y: 0,   z: 100),
            MKSensorData.Triple(x:    0, y: 50,  z: 150),
            MKSensorData.Triple(x:  100, y: 100, z: 200),
        ])
    }
    
    ///
    /// Appending sensor data with too big gap (> 10 seconds) is not allowed
    ///
    func testOneDAppendTooBigGap() {
        var d = threeD
        do {
            try d.append(MKSensorData(dimension: 3, start: 12, samplesPerSecond: 1, samples: [200, 200, 200]))
            XCTFail("Gap too big got in")
        } catch MKSensorDataFailure.TooDiscontinous(11) {
            
        } catch {
            XCTFail("Bad exception")
        }
        
    }
    
}