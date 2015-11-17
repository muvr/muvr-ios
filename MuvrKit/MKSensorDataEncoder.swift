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
    /// The sample dimension
    private let dimension: Int
    /// The samples per second
    private let samplesPerSecond: UInt
    /// The sample interval
    private let sampleInterval: NSTimeInterval
    /// the sample count
    private var sampleCount: UInt32
    /// the first sample date 
    private(set) public var startDate: NSDate?

    ///
    /// Initializes this encoder, setting the target, types, start and sampling rate
    ///
    public init(target: MKSensorDataEncoderTarget, types: [MKSensorDataType], samplesPerSecond: UInt) {
        self.types = types
        self.samplesPerSecond = samplesPerSecond
        self.target = target
        self.sampleCount = 0
        self.startDate = nil
        self.sampleInterval = Double(1) / Double(samplesPerSecond)
        self.dimension = types.reduce(0) { sum, type in return sum + type.dimension }
        
        let emptyHeader = [UInt8](count: 16 + 4 * types.count, repeatedValue: 0)
        target.writeData(NSData(bytes: emptyHeader, length: emptyHeader.count), offset: nil)
    }
    
    ///
    /// Append one "row" containing the sampled values
    /// - parameter sample: the sample
    ///
    public func append(sample: [Float], sampleDate: NSDate) {
        
        func appendSample(sample: [Float]) {
            sampleCount += UInt32(sample.count / dimension)
            target.writeData(NSData(bytes: sample, length: sizeof(Float) * sample.count), offset: nil)
        }

        if sample.count == 0 {
            fatalError("Empty samples.")
        }
        if sample.count % dimension != 0 {
            fatalError("Dimension does not match the sample.")
        }
        if startDate == nil { startDate = sampleDate }

        let expectedSampleCount = UInt32(sampleDate.timeIntervalSinceDate(startDate!) * Double(samplesPerSecond))
        let diff = Int(expectedSampleCount) - Int(sampleCount)
        if diff > 0 {
            // extrapolate
            // TODO: use linear / kalman filter extrapolation, keeping the lastSample
            (0..<diff).forEach { _ in appendSample(sample) }
        } else if diff < 0 {
            // drop
            NSLog("Dropping.")
        } else {
            appendSample(sample)
        }
    }
    
//    private func generateSamples(count count: Int, sample: [Float]) -> [Float] {
//        var samples = [Float](count: count * dimension, repeatedValue: 0)
//        for i in 0..<dimension {
//            let first = sample[i]
//            let last  = lastSample?[i] ?? first
//            let ds = Float(first - last) / Float(count + 1)
//            for j in 0..<count {
//                samples[i + dimension * j] = last + ds * Float(j + 1)
//            }
//        }
//        samples.appendContentsOf(sample)
//        return samples
//    }
    
    ///
    /// Closes the writer the header, and finally closes the given ``target``.
    ///
    public func close() {
        /// the partial headers
        let headerData: NSMutableData = NSMutableData()
        
        var header: UInt8  = 0x61
        var version: UInt8 = 0x64
        var typesCount: UInt8 = UInt8(self.types.count)
        var samplesPerSecond: UInt8 = UInt8(self.samplesPerSecond)
        var sampleCount: UInt32 = self.sampleCount * UInt32(self.dimension)
        var start: Double = startDate?.timeIntervalSince1970 ?? 0
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
    
    /// The duration encoded
    public var duration: NSTimeInterval? {
        if let startDate = startDate, endDate = endDate {
            return endDate.timeIntervalSinceDate(startDate)
        }
        return nil
    }
    
    /// The end date of the encoder
    public var endDate: NSDate? {
        return startDate.map { $0.dateByAddingTimeInterval(Double(sampleCount) / Double(samplesPerSecond)) }
    }
    
}
