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
    /// Encode the MKSensorData instance so that it can be transmitted to over a very low-bandwidth network.
    /// It can throw ``MRCodecError.CompressionFailed`` if for some strange reason the data cannot be compressed.
    ///
    /// - returns: the compressed data that can be passed to ``MKSensorData.decode`` to get the same instance
    ///
    public func encode() -> NSData {
        let data = NSMutableData()
        let encoder = MKSensorDataEncoder(target: MKMutableDataEncoderTarget(data: data), types: self.types, samplesPerSecond: self.samplesPerSecond, startDate: NSDate(timeIntervalSince1970: self.start))
        encoder.append(self.samples, date: NSDate(timeIntervalSince1970: self.end))
        encoder.close(self.start)
        return data
    }
    
}

