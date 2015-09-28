import Foundation
import XCTest
@testable import MuvrKit

class MKSensorDataOneDTests : XCTestCase {
    let oneD   = try! MKSensorData(dimension: 1, start: 0, samplesPerSecond: 1, samples: [100])

    ///
    /// Can't create MKSensorData with bad sample count for the dimension
    ///
    func testBadSampleCountForDimension() {
        if let _ =  try? MKSensorData(dimension: 2, start: 0, samplesPerSecond: 1, samples: [10]) {
            XCTFail("Bad sample count for dimension not detected")
        }
    }
    
    ///
    /// Appending bad dimension is not allowed
    ///
    func testOneDAppendBadDimension() {
        var d = oneD
        do {
            try d.append(try! MKSensorData(dimension: 3, start: 0, samplesPerSecond: 1, samples: [-1000, 0, 1000]))
            XCTFail("Appended incorrect dimension")
        } catch MKSensorDataFailure.MismatchedDimension(1, 3) {
            
        } catch {
            XCTFail("Bad error")
        }
    }
    
    ///
    /// Appending bad sampling rate is not allowed
    ///
    func testOneDAppendBadSamplingRate() {
        var d = oneD
        do {
            try d.append(MKSensorData(dimension: 1, start: 1, samplesPerSecond: 2, samples: [100]))
            XCTFail("Appended incorrect sampling rate")
        } catch MKSensorDataFailure.MismatchedSamplesPerSecond(1, 2) {
            
        } catch {
            XCTFail("Bad error")
        }
    }
    
    /// ```
    ///   S1
    /// +  0
    /// ====
    ///   S1
    /// ```
    func testOneDAppendEmpty() {
        var d = oneD
        try! d.append(MKSensorData(dimension: 1, start: 0, samplesPerSecond: 1, samples: []))
        XCTAssertEqual(d.end, 1)
    }
    
    /// ```
    ///   S1
    /// + S2
    /// ====
    ///   S2
    /// ```
    func testOneDAppendCompletelyOverlapping() {
        var d = oneD
        try! d.append(oneD)
        XCTAssertEqual(d.end, 1)
    }
    
    /// ```
    ///   S1
    /// +   S2
    /// ======
    ///   S1S2
    /// ```
    func testOneDAppendImmediatelyFollowing() {
        var d = oneD    // end == 1
        try! d.append(MKSensorData(dimension: 1, start: 1, samplesPerSecond: 1, samples: [130])) // end == 2
        try! d.append(MKSensorData(dimension: 1, start: 2, samplesPerSecond: 1, samples: [140, 140])) // end == 4
        XCTAssertEqual(d.end, 4)
        XCTAssertEqual(try! d.samplesAsScalars(), [100, 130, 140, 140])
    }
    
    /// ```
    ///  S1
    /// +  .g.S2
    /// +       ·g·S3
    /// =============
    ///  S1...S2···S3
    /// ```
    func testOneDAppendAllowableGap() {
        var d = oneD
        try! d.append(MKSensorData(dimension: 1, start: 2, samplesPerSecond: 1, samples: [200]))
        XCTAssertEqual(d.end, 3)
        XCTAssertEqual(try! d.samplesAsScalars(), [100, 150, 200])
        
        try! d.append(MKSensorData(dimension: 1, start: 6, samplesPerSecond: 1, samples: [400, 200, 200, 100]))
        XCTAssertEqual(d.end, 10)
        XCTAssertEqual(try! d.samplesAsScalars(), [100, 150, 200, 250, 300, 350, 400, 200, 200, 100])
    }
    
    ///
    /// Appending sensor data with too big gap (> 10 seconds) is not allowed
    ///
    func testOneDAppendTooBigGap() {
        var d = oneD
        do {
            try d.append(MKSensorData(dimension: 1, start: 12, samplesPerSecond: 1, samples: [200]))
            XCTFail("Gap too big got in")
        } catch MKSensorDataFailure.TooDiscontinous(11) {
            
        } catch {
            XCTFail("Bad exception")
        }
        
    }

}
