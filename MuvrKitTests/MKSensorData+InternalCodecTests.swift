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
            _ = try MKSensorData(decoding: "123456789abcdef1011".dataUsingEncoding(NSASCIIStringEncoding)!)
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
            let wrongData = NSMutableData(data: encoded.subdataWithRange(NSRange(location: 0, length: 17)))
            wrongData.appendData("....".dataUsingEncoding(NSASCIIStringEncoding)!)
            _ = try MKSensorData(decoding: wrongData)
            XCTFail("Not caught")
        } catch MKCodecError.BadHeader {
        } catch {
            XCTFail("Bad exception")
        }
    }

    func testEncodeDecodeWithStartDate() {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let start = dateFormatter.dateFromString("2030-02-28")
        
        let d = try! MKSensorData(
            types: [.Accelerometer(location: .RightWrist), .Accelerometer(location: .LeftWrist),
                .Gyroscope(location: .RightWrist), .Gyroscope(location: .LeftWrist), .HeartRate],
            start: (start?.timeIntervalSinceReferenceDate)!,
            samplesPerSecond: 1,
            samples: [Float](count: 1300, repeatedValue: 0)
        )
        
        let encoded = d.encode()
        let dx = try! MKSensorData(decoding: encoded)
        let decodeStart = NSDate(timeIntervalSinceReferenceDate: dx.start)
        XCTAssertEqual(d, dx)
        XCTAssertEqual(start, decodeStart)
    }
    
    func testDecodePebbleSensorData() {
        let bytes: [UInt8] = [0x61, 0x65, 0x01, 0x32, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x96, 0x00, 0x00, 0x00, 0x74, 0x61, 0x6c, 0x00, 0x18, 0x1c, 0x7d, 0xe0, 0xf8, 0x17, 0x3c, 0x7d, 0xe0, 0xf8, 0x16, 0x5c, 0x7d, 0xe0, 0xf8, 0x15, 0x7c, 0x7d, 0xe0, 0xf8, 0x14, 0x9c, 0x7d, 0xe0, 0xf8, 0x13, 0xbc, 0x7d, 0xe0, 0xf8, 0x12, 0xdc, 0x7d, 0xe0, 0xf8, 0x11, 0xfc, 0x7d, 0xe0, 0xf8, 0x10, 0x1c, 0x7e, 0xe0, 0xf8, 0x0f, 0x3c, 0x7e, 0xe0, 0xf8, 0x0e, 0x5c, 0x7e, 0xe0, 0xf8, 0x0d, 0x7c, 0x7e, 0xe0, 0xf8, 0x0c, 0x9c, 0x7e, 0xe0, 0xf8, 0x0b, 0xbc, 0x7e, 0xe0, 0xf8, 0x0a, 0xdc, 0x7e, 0xe0, 0xf8, 0x09, 0xfc, 0x7e, 0xe0, 0xf8, 0x08, 0x1c, 0x7f, 0xe0, 0xf8, 0x07, 0x3c, 0x7f, 0xe0, 0xf8, 0x06, 0x5c, 0x7f, 0xe0, 0xf8, 0x05, 0x7c, 0x7f, 0xe0, 0xf8, 0x04, 0x9c, 0x7f, 0xe0, 0xf8, 0x03, 0xbc, 0x7f, 0xe0, 0xf8, 0x02, 0xdc, 0x7f, 0xe0, 0xf8, 0x01, 0xfc, 0x7f, 0xe0, 0xf8, 0x00, 0x1c, 0x80, 0xe0, 0xf8, 0xff, 0x3b, 0x80, 0xe0, 0xf8, 0xfe, 0x5b, 0x80, 0xe0, 0xf8, 0xfd, 0x7b, 0x80, 0xe0, 0xf8, 0xfc, 0x9b, 0x80, 0xe0, 0xf8, 0xfb, 0xbb, 0x80, 0xe0, 0xf8, 0xfa, 0xdb, 0x80, 0xe0, 0xf8, 0xf9, 0xfb, 0x80, 0xe0, 0xf8, 0xf8, 0x1b, 0x81, 0xe0, 0xf8, 0xf7, 0x3b, 0x81, 0xe0, 0xf8, 0xf6, 0x5b, 0x81, 0xe0, 0xf8, 0xf5, 0x7b, 0x81, 0xe0, 0xf8, 0xf4, 0x9b, 0x81, 0xe0, 0xf8, 0xf3, 0xbb, 0x81, 0xe0, 0xf8, 0xf2, 0xdb, 0x81, 0xe0, 0xf8, 0xf1, 0xfb, 0x81, 0xe0, 0xf8, 0xf0, 0x1b, 0x82, 0xe0, 0xf8, 0xef, 0x3b, 0x82, 0xe0, 0xf8, 0xee, 0x5b, 0x82, 0xe0, 0xf8, 0xed, 0x7b, 0x82, 0xe0, 0xf8, 0xec, 0x9b, 0x82, 0xe0, 0xf8, 0xeb, 0xbb, 0x82, 0xe0, 0xf8, 0xea, 0xdb, 0x82, 0xe0, 0xf8, 0xe9, 0xfb, 0x82, 0xe0, 0xf8, 0xe8, 0x1b, 0x83, 0xe0, 0xf8, 0xe7, 0x3b, 0x83, 0xe0, 0xf8]
        
        let data = NSData(bytes: bytes, length: bytes.count)
        let sensorData = try! MKSensorData(decoding: data)
        XCTAssertEqual(50, sensorData.rowCount)
        
        XCTAssertEqual(-1000/4095, sensorData.samples[0])
        XCTAssertEqual(1000/4095, sensorData.samples[1])
        XCTAssertEqual(-456/4095, sensorData.samples[2])
        
        XCTAssertEqual(-1049/4095, sensorData.samples[147])
        XCTAssertEqual(1049/4095, sensorData.samples[148])
        XCTAssertEqual(-456/4095, sensorData.samples[149])
    }

}
