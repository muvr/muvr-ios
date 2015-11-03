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
    
    ///
    /// Tests that not enough input is caught
    ///
    func testDecodeNotEnoughInput() {
        do {
            try _ = MKSensorData(decoding: NSData())
            XCTFail("Not thrown")
        } catch MKCodecError.NotEnoughInput {
            // OK
        } catch {
            XCTFail("Bad exception")
        }
    }
    
    ///
    /// We can decode each block
    /// [PEBBLE raw file is no longer valid - disabled test]
    ///
//    func testDecode() {
//        mapBlockFrom(resourceName: "pebble-1") { blockData in
//            let sd = try! MKSensorData(decoding: blockData)
//            
//            // expect 100 samples
//            XCTAssertEqual(sd.samples.count, 300)
//            XCTAssertEqual(sd.dimension, 3)
//            XCTAssertEqual(sd.types, [.Accelerometer(location: .LeftWrist)])
//        }
//    }
    
    ///
    /// We can decode and append entire Pebble session
    /// [PEBBLE raw file is no longer valid - disabled test]
    ///
//    func testDecodeAndAppend() {
//        let blocks = mapBlockFrom(resourceName: "pebble-1") { try! MKSensorData(decoding: $0) }
//        var sd = blocks.first!
//        blocks.dropFirst().forEach { try! sd.append($0) }
//        
//        print(sd)
//    }
    
}
