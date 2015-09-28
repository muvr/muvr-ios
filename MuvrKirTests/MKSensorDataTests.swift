import Foundation
import XCTest
@testable import MuvrKit

class MKSensorDataTests: XCTestCase {
    let oneD   = try! MKSensorData(dimension: 1, start: 0, samplesPerSecond: 1, samples: [100])
    let threeD = try! MKSensorData(dimension: 3, start: 0, samplesPerSecond: 1, samples: [-1000, 0, 1000])

    func testBadSampleCountForDimension() {
        if let _ =  try? MKSensorData(dimension: 2, start: 0, samplesPerSecond: 1, samples: [10]) {
            XCTFail("Bad sample count for dimension not detected")
        }
    }
    
    func testOneDCompletelyOverlapping() {
        var d = oneD
        try! d.append(oneD)
        XCTAssertEqual(d.end, 1)
    }
    
    func testOneDImmediatelyFollowing() {
        var d = oneD
        try! d.append(MKSensorData(dimension: 1, start: 1, samplesPerSecond: 1, samples: [130]))
        try! d.append(MKSensorData(dimension: 1, start: 2, samplesPerSecond: 1, samples: [140, 140]))
        XCTAssertEqual(d.end, 4)
        XCTAssertEqual(try! d.samplesAsScalars(), [100, 130, 140, 140])
    }
    
    func testOneDAllowableGap() {
        var d = oneD
        try! d.append(MKSensorData(dimension: 1, start: 2, samplesPerSecond: 1, samples: [200]))
        XCTAssertEqual(d.end, 3)
        XCTAssertEqual(try! d.samplesAsScalars(), [100, 150, 200])
        
        try! d.append(MKSensorData(dimension: 1, start: 6, samplesPerSecond: 1, samples: [400, 200, 200, 100]))
        XCTAssertEqual(d.end, 10)
        XCTAssertEqual(try! d.samplesAsScalars(), [100, 150, 200, 250, 300, 350, 400, 200, 200, 100])
    }

}