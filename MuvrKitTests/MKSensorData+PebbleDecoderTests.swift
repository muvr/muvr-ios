import Foundation
import XCTest
@testable import MuvrKit

class MKSensorDataPebbleCodecTests : XCTestCase {

    private func mapBlockFrom<A>(resourceName resourceName: String, f: NSData -> A) -> [A] {
        let data = NSData(contentsOfFile: NSBundle(forClass: MKSensorDataPebbleCodecTests.self).pathForResource(resourceName, ofType: "raw")!)!
        let blockSize = 516
        let blockCount = data.length / blockSize
        
        return (0..<blockCount).map { idx in
            let blockData = data.subdataWithRange(NSRange(location: idx * blockSize, length: blockSize))
            return f(blockData)
        }
    }
    
    func testDecode() {
        mapBlockFrom(resourceName: "pebble-1") { blockData in
            let sd = try! MKSensorData(decodingPebble: blockData)
            
            // expect 100 samples
            XCTAssertEqual(sd.samples.count, 300)
            XCTAssertEqual(sd.dimension, 3)
            XCTAssertEqual(sd.types, [.Accelerometer(location: .LeftWrist)])
        }
    }
    
    func testDecodeAndAppend() {
        let blocks = mapBlockFrom(resourceName: "pebble-1") { try! MKSensorData(decodingPebble: $0) }
        var sd = blocks.first!
        blocks.dropFirst().forEach { try! sd.append($0) }
        
        print(sd)
    }
    
}
