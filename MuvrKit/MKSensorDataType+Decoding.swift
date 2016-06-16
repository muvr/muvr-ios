import Foundation

extension MKSensorDataType {
    private static let header: UInt8 = 0x74

    static func decode(_ bytes: MKUnsafeBufferReader) throws -> MKSensorDataType {
        if bytes.length < 4 { throw MKCodecError.notEnoughInput }

        if try bytes.next() != header { throw MKCodecError.badHeader }
        let sensor: UInt8 = try bytes.next()
        let location: UInt8 = try bytes.next()
        try bytes.next() as UInt8 // not used but still need to be read
        
        switch (sensor, location) {
        case (UInt8(0x61), UInt8(0x6c)): return .accelerometer(location: .leftWrist)
        case (UInt8(0x61), UInt8(0x72)): return .accelerometer(location: .rightWrist)
        case (UInt8(0x67), UInt8(0x6c)): return .gyroscope(location: .leftWrist)
        case (UInt8(0x67), UInt8(0x72)): return .gyroscope(location: .rightWrist)
        case (UInt8(0x68), _):           return .heartRate
        default:                         throw MKCodecError.badHeader
        }
        
    }

}
