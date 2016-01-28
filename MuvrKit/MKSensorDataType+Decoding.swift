import Foundation

extension MKSensorDataType {
    private static let header: UInt8 = 0x74

    static func decode(bytes: MKUnsafeBufferReader) throws -> MKSensorDataType {
        if bytes.length < 4 { throw MKCodecError.NotEnoughInput }

        let b0: UInt8 = try bytes.next()
        let b1: UInt8 = try bytes.next()
        let b2: UInt8 = try bytes.next()
        let b3: UInt8 = try bytes.next()
        
        switch (b0, b1, b2, b3) {
        case (header, UInt8(0x61), UInt8(0x6c), UInt8(0x51)): return .Accelerometer(location: Location.LeftWrist, dataFormat: SensorDataFormat.Int16)
        case (header, UInt8(0x61), UInt8(0x6c), _):           return .Accelerometer(location: Location.LeftWrist, dataFormat: SensorDataFormat.Float32)
        case (header, UInt8(0x61), UInt8(0x72), UInt8(0x51)): return .Accelerometer(location: Location.RightWrist, dataFormat: SensorDataFormat.Int16)
        case (header, UInt8(0x61), UInt8(0x72), _):           return .Accelerometer(location: Location.RightWrist, dataFormat: SensorDataFormat.Float32)
        case (header, UInt8(0x67), UInt8(0x6c), _): return .Gyroscope(location: Location.LeftWrist)
        case (header, UInt8(0x67), UInt8(0x72), _): return .Gyroscope(location: Location.RightWrist)
        case (header, UInt8(0x68), _, _):           return .HeartRate
        default:                                    throw MKCodecError.BadHeader
        }
        
    }

}
