import Foundation

extension MKSensorDataType {
    private static let header: UInt8 = 0xf0

    static func decode(bytes: MKUnsafeBufferReader) throws -> MKSensorDataType {
        if bytes.length < 3 { throw MKCodecError.NotEnoughInput }

        let b0: UInt8 = try bytes.next()
        let b1: UInt8 = try bytes.next()
        let b2: UInt8 = try bytes.next()
        
        switch (b0, b1, b2) {
        case (header, UInt8(0x01), UInt8(0x01)): return .Accelerometer(location: Location.LeftWrist)
        case (header, UInt8(0x01), UInt8(0x02)): return .Accelerometer(location: Location.RightWrist)
        case (header, UInt8(0x02), UInt8(0x01)): return .Gyroscope(location: Location.LeftWrist)
        case (header, UInt8(0x02), UInt8(0x02)): return .Gyroscope(location: Location.RightWrist)
        case (header, UInt8(0x03), _):           return .HeartRate
        default:                                 throw MKCodecError.BadHeader
        }
        
    }

}
