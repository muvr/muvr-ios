import Foundation
import XCTest
@testable import MuvrKit

class MKSensorDataInternalCodecTests : XCTestCase {
    
    func testNotEnoughInput() {
        do {
            _ = try MKSensorData(decoding: NSData())
            XCTFail("Not caught")
        } catch MKCodecError.NotEnoughInput {
        } catch {
            XCTFail("Bad exception thrown")
        }
    }
    
    func testMalicious() {
        do {
            _ = try MKSensorData(decoding: "ad\u{01}ssssssssfcccctar.".dataUsingEncoding(NSASCIIStringEncoding)!)
            XCTFail("Not caught")
        } catch MKCodecError.NotEnoughInput {
        } catch {
            XCTFail("Bad exception \(error)")
        }
    }
    
    func testEncodeDecode() {
        let d = try! MKSensorData(
            types: [.Accelerometer(location: .RightWrist), .Accelerometer(location: .LeftWrist),
                    .Gyroscope(location: .RightWrist), .Gyroscope(location: .LeftWrist), .HeartRate],
            start: 0,
            samplesPerSecond: 1,
            samples: [Float](count: 1300, repeatedValue: 0)
        )
        
        let encoded = d.encode()
        let dx = try! MKSensorData(decoding: encoded)
        XCTAssertEqual(d, dx)
    }
    
    func testMalformedHeader() {
        do {
            _ = try MKSensorData(decoding: "123456789abcdef10".dataUsingEncoding(NSASCIIStringEncoding)!)
            XCTFail("Not caught")
        } catch MKCodecError.BadHeader {
        } catch {
            XCTFail("Bad exception")
        }
    }

    func testTruncatedInput() {
        let d = try! MKSensorData(
            types: [.HeartRate],
            start: 0,
            samplesPerSecond: 1,
            samples: [Float](count: 100, repeatedValue: 0)
        )
        
        let encoded = d.encode()

        do {
            _ = try MKSensorData(decoding: encoded.subdataWithRange(NSRange(location: 0, length: 17)))
            XCTFail("Not caught")
        } catch MKCodecError.NotEnoughInput {
        } catch {
            XCTFail("Bad exception")
        }

        do {
            let wrongData = NSMutableData(data: encoded.subdataWithRange(NSRange(location: 0, length: 16)))
            wrongData.appendData("...".dataUsingEncoding(NSASCIIStringEncoding)!)
            _ = try MKSensorData(decoding: wrongData)
            XCTFail("Not caught")
        } catch MKCodecError.BadHeader {
        } catch {
            XCTFail("Bad exception")
        }
    }
    
//TODO run on device
    
//    func test1() {
//        let d = NSMutableData()
//        
//        var var1: UInt8  = 0x61
//        var var2: UInt8 = 0x62
//        var var3: UInt8 = 0x63
//        var var4: UInt8 = 0x64
//        var vardouble: Double = 0.0
//        
//        d.appendBytes(&var1,  length: sizeof(UInt8))
//        d.appendBytes(&var2, length: sizeof(UInt8))
//        d.appendBytes(&var3, length: sizeof(UInt8))
//        //d.appendBytes(&var4, length: sizeof(UInt8))
//        d.appendBytes(&vardouble, length: sizeof(Double))
//        let bytes = MKUnsafeBufferReader(data: d)
//        
//        do {
//            let res1: UInt8 = try bytes.next()
//            XCTAssertEqual(UInt8(0x61), res1)
//            
//            let res2: UInt8 = try bytes.next()
//            XCTAssertEqual(UInt8(0x62), res2)
//            
//            let res3: UInt8 = try bytes.next()
//            XCTAssertEqual(UInt8(0x63), res3)
//            
////            let res4: UInt8 = try bytes.next()
////            XCTAssertEqual(UInt8(0x64), res4)
//            
//            let res5: Double = try bytes.next()
//            XCTAssertEqual(0.0, res5)
//            
//        } catch {
//            XCTFail()
//        }
//    }

}
