import Foundation

public protocol MKSensorDataEncoderTarget {
    
    func writeData(data: NSData, offset: UInt64?)
    
    func close()
}

public class MKFileSensorDataEncoderTarget : MKSensorDataEncoderTarget {
    private let handle: NSFileHandle
    
    public init(fileUrl: NSURL) {
        try! "".writeToURL(fileUrl, atomically: true, encoding: NSASCIIStringEncoding)
        self.handle = try! NSFileHandle(forWritingToURL: fileUrl)
    }
    
    public func writeData(data: NSData, offset: UInt64?) {
        if let offset = offset {
            handle.seekToFileOffset(offset)
        }
        handle.writeData(data)
    }
    
    public func close() {
        handle.closeFile()
    }
    
}

public class MKMutableDataEncoderTarget : MKSensorDataEncoderTarget {
    private let data: NSMutableData
    private var offset: UInt64 = 0
    
    public init(data: NSMutableData) {
        self.data = data
    }
    
    public func writeData(data: NSData, offset: UInt64?) {
        if let offset = offset {
            self.data.replaceBytesInRange(NSRange(location: Int(offset), length: data.length), withBytes: data.bytes, length: data.length)
        } else {
            self.data.appendData(data)
        }
    }
    
    public func close() {
        
    }
    
    
}

///
/// Provides direct-to-file encoding for the ``MKSensorData``
///
public final class MKSensorDataEncoder {
    /// the target
    private let target: MKSensorDataEncoderTarget
    /// The types of data contained in the column vectors (or spans of column vectors)
    private let types: [MKSensorDataType]
    /// The samples per second
    private let samplesPerSecond: UInt
    /// the sample count
    private var sampleCount: UInt32

    ///
    /// Initializes this encoder, setting the target, types, start and sampling rate
    ///
    public init(target: MKSensorDataEncoderTarget, types: [MKSensorDataType], samplesPerSecond: UInt) {
        self.types = types
        self.samplesPerSecond = samplesPerSecond
        self.target = target
        self.sampleCount = 0
        
        let emptyHeader = [UInt8](count: 16 + 4 * types.count, repeatedValue: 0)
        target.writeData(NSData(bytes: emptyHeader, length: emptyHeader.count), offset: nil)
    }
    
    ///
    /// Append one "row" containing the sampled values
    /// - parameter sample: the sample
    ///
    public func append(sample: [Float]) {
        sampleCount += UInt32(sample.count)
        target.writeData(NSData(bytes: sample, length: sizeof(Float) * sample.count), offset: nil)
    }
    
    ///
    /// Closes 
    ///
    public func close(start: NSTimeInterval) {
        /// the partial headers
        let headerData: NSMutableData = NSMutableData()
        
        var header: UInt8  = 0x61
        var version: UInt8 = 0x64
        var typesCount: UInt8 = UInt8(self.types.count)
        var samplesPerSecond: UInt8 = UInt8(self.samplesPerSecond)

        var start: Double = start
        var types = self.types.flatMap { (type: MKSensorDataType) -> [UInt8] in
            switch type {
            case .Accelerometer(location: MKSensorDataType.Location.LeftWrist):  return [UInt8(0x74), UInt8(0x61), UInt8(0x6c), UInt8(0x0)]
            case .Accelerometer(location: MKSensorDataType.Location.RightWrist): return [UInt8(0x74), UInt8(0x61), UInt8(0x72), UInt8(0x0)]
            case .Gyroscope(location: MKSensorDataType.Location.LeftWrist):      return [UInt8(0x74), UInt8(0x67), UInt8(0x6c), UInt8(0x0)]
            case .Gyroscope(location: MKSensorDataType.Location.RightWrist):     return [UInt8(0x74), UInt8(0x67), UInt8(0x72), UInt8(0x0)]
            case .HeartRate:                                                     return [UInt8(0x74), UInt8(0x68), UInt8(0x2d), UInt8(0x0)]
            }
        }
        
        headerData.appendBytes(&header,  length: sizeof(UInt8))           // 1
        headerData.appendBytes(&version, length: sizeof(UInt8))           // 2
        headerData.appendBytes(&typesCount, length: sizeof(UInt8))        // 3
        headerData.appendBytes(&samplesPerSecond, length: sizeof(UInt8))  // 4
        headerData.appendBytes(&start, length: sizeof(Double))            // 12
        headerData.appendBytes(&sampleCount, length: sizeof(UInt32))      // 16
        headerData.appendBytes(&types, length: types.count)               // 16 + 4 * |types|

        target.writeData(headerData, offset: 0)
        target.close()
    }
    
}
