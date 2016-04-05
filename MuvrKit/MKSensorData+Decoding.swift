import Foundation

///
/// We have the
///
/// ```
/// uint32_t decompressedSize;
/// compressed struct MK_SENSOR_DATA_HEADER {
///    uint8_t header = 0xd0;        
///    uint8_t version = 1;          
///    uint8_t typesCount;           
///    double  start;                
///    uint8_t samplesPerSecod;
///    uint32  samplesCount;         
///
///    uint8_t types[typesCount];    
///    uint8_t samples[samplesCount];
/// }
/// ```
///
public extension MKSensorData {
    
    ///
    /// Initializes this instance by decoding the given ``data``. This is the inverse function
    /// of ``MKSensorData.encode()``: given enough memory, this always holds.
    ///
    /// ```
    /// let a = MKSensorData(...)
    /// let b = MKSensorData(decoding: a.encode())
    /// assert(a == b)
    /// ```
    ///
    /// - parameter data: the data to be decoded
    ///
    public init(decoding data: NSData) throws {
        
        enum Device: UInt8 {
            case AppleWatch = 0x64
            case Pebble = 0x65
        }
        
        let bytes = MKUnsafeBufferReader(data: data)

        if bytes.length < 18 { throw MKCodecError.NotEnoughInput }
        
        try bytes.expect(UInt8(0x61), throwing: MKCodecError.BadHeader) // 1
        let device = try Device(rawValue: bytes.next())                 // 2
        
        if (device == nil) { throw MKCodecError.BadHeader }
        
        let typesCount: UInt8       = try bytes.next()                  // 3
        let samplesPerSecond: UInt8 = try bytes.next()                  // 4
        let start: Double           = try bytes.next()                  // 8
        let valuesCount: UInt32     = try bytes.next()                  // 12
        let types = try (0..<typesCount).map { _ in                     // 18
            return try MKSensorDataType.decode(bytes)
        }

        var samples: [Float] = [Float](count: Int(valuesCount), repeatedValue: 0)
        
        for i in 0..<Int(valuesCount) {
            switch(device!) {
            case .AppleWatch: samples[i] = try bytes.next()
            case .Pebble: throw MKCodecError.NotSupported
            }
            
        }
        
        try self.init(types: types, start: start, samplesPerSecond: UInt(samplesPerSecond), samples: samples)
    }
}
