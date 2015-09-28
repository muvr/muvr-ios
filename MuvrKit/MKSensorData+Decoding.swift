import Foundation
import Compression

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
///    uint8   samplesPerSecod;      
///    uint32  samplesCount;         
///
///    uint8_t types[typesCount];    
///    uint8_t samples[samplesCount];
/// }
/// ```
///
public extension MKSensorData {
    
    ///
    /// Initializes this instance by decoding the given ``data``.
    ///
    /// - parameter data: the data to be decoded
    ///
    public init(decoding data: NSData) throws {
        let destinationBufferSize: Int = Int(UnsafePointer<UInt32>(data.bytes).memory)
        let sourceBuffer: UnsafePointer<UInt8> = UnsafePointer<UInt8>(data.bytes.advancedBy(sizeof(UInt32)))
        let sourceBufferSize: Int = data.length
        
        let destinationBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.alloc(destinationBufferSize)
        let status = compression_decode_buffer(destinationBuffer, destinationBufferSize, sourceBuffer, sourceBufferSize, nil, COMPRESSION_LZFSE)
        if status == 0 {
            throw MKCodecError.DecompressionFailed
        }
        
        let bytes = MKUnsafeBufferReader(bytes: destinationBuffer, totalLength: status)

        if bytes.length < 5 { throw MKCodecError.NotEnoughInput }
        
        try bytes.expect(UInt8(0xd0))
        try bytes.expect(UInt8(1))
        let typesCount: UInt8       = try bytes.next()
        let start: Double           = try bytes.next()
        let samplesPerSecond: UInt8 = try bytes.next()
        let samplesCount: UInt32    = try bytes.next()
        
        let types = try (0..<typesCount).map { _ in
            return try MKSensorDataType.decode(bytes)
        }
        let samplesData: UnsafePointer<Float> = try bytes.nexts(Int(samplesCount))
        var samples: [Float] = [Float](count: Int(samplesCount), repeatedValue: 0)
        for i in 0..<Int(samplesCount) {
            samples[i] = samplesData.advancedBy(i).memory
        }
        
        try self.init(types: types, start: start, samplesPerSecond: UInt(samplesPerSecond), samples: samples)
    }
    
}
