import Foundation

extension MKSensorDataType {
    private static let header: UInt8 = 0x74

    static func decode(bytes: MKUnsafeBufferReader) throws -> MKSensorDataType {
        if bytes.length < 4 { throw MKCodecError.NotEnoughInput }

        if try bytes.next() != header { throw MKCodecError.BadHeader }
        let sensor: UInt8 = try bytes.next()
        let location: UInt8 = try bytes.next()
        try bytes.next() as UInt8 // not used but still need to be read
        
        switch (sensor, location) {
        case (UInt8(0x61), UInt8(0x6c)): return .Accelerometer(location: .LeftWrist)
        case (UInt8(0x61), UInt8(0x72)): return .Accelerometer(location: .RightWrist)
        case (UInt8(0x67), UInt8(0x6c)): return .Gyroscope(location: .LeftWrist)
        case (UInt8(0x67), UInt8(0x72)): return .Gyroscope(location: .RightWrist)
        case (UInt8(0x68), _):           return .HeartRate
        default:                         throw MKCodecError.BadHeader
        }
        
    }

}
