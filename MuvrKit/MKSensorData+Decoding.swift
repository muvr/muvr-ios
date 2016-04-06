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
        
        guard let device = try Device(rawValue: bytes.next()) else { throw MKCodecError.BadHeader } // 2
        
        let typesCount: UInt8       = try bytes.next()                  // 3
        let samplesPerSecond: UInt8 = try bytes.next()                  // 4
        let start: Double           = try bytes.next()                  // 8
        let valuesCount: UInt32     = try bytes.next()                  // 12
        let types = try (0..<typesCount).map { _ in                     // 18
            return try MKSensorDataType.decode(bytes)
        }

        var samples: [Float] = [Float](count: Int(valuesCount), repeatedValue: 0)
        
        switch device  {
        case .AppleWatch:
            for i in 0..<Int(valuesCount) { samples[i] = try bytes.next() }
        case .Pebble:
            for i in 0..<Int(valuesCount) / 3 {
                let (x, y, z) = try bytes.nextPebbleSample()
                samples[3 * i] = x
                samples[3 * i + 1] = y
                samples[3 * i + 2] = z
            }
        }
        
        
        try self.init(types: types, start: start, samplesPerSecond: UInt(samplesPerSecond), samples: samples)
    }
}

private extension MKUnsafeBufferReader {

    /// read n bytes from the bytes buffer
    /// and return them into an array of UInt8
    func nextBytes(n: Int) throws -> [UInt8] {
        var bytes = [UInt8](count: n, repeatedValue: 0)
        for i in 0..<bytes.count {
            bytes[i] = try next()
        }
        return bytes
    }
    
    /// Reads 5 bytes from the given buffer corresponding to x,y,z values.
    /// x,y,z values are encoded on 13, 13 and 14 bits respectively (total: 40 bits)
    /// - returns the x,y,z values as a tuple
    func nextPebbleSample() throws -> (Float, Float, Float) {
        // read 40 bits and store each of them into UInt16 to ease bit handling
        var ints = try nextBytes(5).map { UInt16($0) }
        
        // Move bits around to get the correct values
        var z = (ints[4] << 6) | (ints[3] >> 2) // 14 bits
        var y = ((ints[3] & 0x03) << 10) | (ints[2] << 3) | (ints[1] >> 5) // 13 bits
        var x = ((ints[1] & 0x1F) << 8) | ints[0] // 13 bits
        
        // Handle signs
        if z & 0x1000 > 0 { z |= 0xE000 }
        if y & 0x1000 > 0 { y |= 0xE000 }
        if x & 0x1000 > 0 { x |= 0xE000 }
        
        // Convert to signed float
        return (Float(Int16(bitPattern: x)), Float(Int16(bitPattern: y)), Float(Int16(bitPattern: z)))
    }
    
}

