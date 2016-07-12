import Foundation

///
/// Abstract over the ``target`` where the data is written (e.g. file or memory)
///
public protocol MKSensorDataEncoderTarget {
    
    func writeData(_ data: Data, offset: UInt64?)
    
    func close()
}

///
/// Provides write access to a file
///
public class MKFileSensorDataEncoderTarget : MKSensorDataEncoderTarget {
    private let handle: FileHandle
    
    public init(fileUrl: URL) {
        try! "".write(to: fileUrl, atomically: true, encoding: .ascii)
        self.handle = try! FileHandle(forWritingTo: fileUrl)
    }
    
    public func writeData(_ data: Data, offset: UInt64?) {
        if let offset = offset {
            handle.seek(toFileOffset: offset)
        }
        handle.write(data)
    }
    
    public func close() {
        handle.closeFile()
    }
    
}

///
/// Provides write access to memory
///
public class MKMutableDataEncoderTarget : MKSensorDataEncoderTarget {
    private let data: NSMutableData
    private var offset: UInt64 = 0
    
    public init(data: NSMutableData) {
        self.data = data
    }
    
    public func writeData(_ data: Data, offset: UInt64?) {
        if let offset = offset {
            //self.data.replaceBytesInRange(NSRange(location: Int(offset), length: data.length), withBytes: data.bytes, length: data.length)
            data.withUnsafeBytes { bytes in
                self.data.replaceBytes(in: NSRange(location: Int(offset), length: data.count), withBytes: bytes, length: data.count)
            }
        } else {
            self.data.append(data)
        }
    }
    
    public func close() {
        
    }
    
    
}

///
/// Provides direct-to-file/memory encoding for the ``MKSensorData``
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
    /// the sample count
    private var sampleCount: UInt32
    /// the first sample date
    private(set) public var startDate: Date?
    /// the last written sample
    private var lastSample: [Float]?
    ///

    ///
    /// Initializes this encoder, setting the target, types, start and sampling rate
    ///
    public init(target: MKSensorDataEncoderTarget, types: [MKSensorDataType], samplesPerSecond: UInt) {
        self.types = types
        self.samplesPerSecond = samplesPerSecond
        self.target = target
        self.sampleCount = 0
        self.dimension = types.reduce(0) { sum, type in return sum + type.dimension }

        let emptyHeader = [UInt8](repeating: 0, count: 16 + 4 * types.count)
        target.writeData(Data(bytes: emptyHeader), offset: nil)
    }
    
    ///
    /// Append one "row" containing the sampled values
    /// - parameter sample: the sample
    ///
    public func append(_ sample: [Float], sampleDate: Date) {
        
        func appendSample(_ sample: [Float]) {
            sampleCount += UInt32(sample.count / dimension)
            let d = NSData(bytes: sample, length: sizeof(Float.self) * sample.count)
            target.writeData(d as Data, offset: nil)
        }
        
        /// generate missing samples between ``lastSample`` and new ``sample``
        /// using linear interpolation
        func generateSamples(_ count: Int) -> [Float] {
            var samples = [Float](repeating: 0, count: count * dimension)
            for i in 0..<dimension {
                let first = sample[i]
                let last  = lastSample?[i] ?? first
                let ds = Float(first - last) / Float(count + 1)
                for j in 0..<count {
                    samples[i + dimension * j] = last + ds * Float(j + 1)
                }
            }
            samples.append(contentsOf: sample)
            return samples
        }

        if sample.count == 0 {
            fatalError("Empty samples.")
        }
        if sample.count % dimension != 0 {
            fatalError("Dimension does not match the sample.")
        }
        
        if startDate == nil { startDate = sampleDate }
        
        let expectedSampleCount = UInt32(round(sampleDate.timeIntervalSince(startDate!) * Double(samplesPerSecond)))
        let diff = Int(expectedSampleCount) - Int(sampleCount)
        if diff > 0 {
            // extrapolate
            // TODO: use linear / kalman filter extrapolation, keeping the lastSample
            NSLog("Extrapolate \(diff) samples.")
            // (0..<diff).forEach { _ in appendSample(sample) }
            let samples = generateSamples(diff)
            appendSample(samples)
            lastSample = sample
        } else if diff < 0 {
            // drop
            NSLog("Dropping.")
        } else {
            appendSample(sample)
            lastSample = sample
        }
    }
    
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
        var start: Double = startDate?.timeIntervalSinceReferenceDate ?? 0
        var types = self.types.flatMap { (type: MKSensorDataType) -> [UInt8] in
            switch type {
            case .accelerometer(location: .leftWrist):  return [UInt8(0x74), UInt8(0x61), UInt8(0x6c), UInt8(0x52)]
            case .accelerometer(location: .rightWrist): return [UInt8(0x74), UInt8(0x61), UInt8(0x72), UInt8(0x52)]
            case .gyroscope(location: MKSensorDataType.Location.leftWrist):      return [UInt8(0x74), UInt8(0x67), UInt8(0x6c), UInt8(0x0)]
            case .gyroscope(location: MKSensorDataType.Location.rightWrist):     return [UInt8(0x74), UInt8(0x67), UInt8(0x72), UInt8(0x0)]
            case .heartRate:                                                     return [UInt8(0x74), UInt8(0x68), UInt8(0x2d), UInt8(0x0)]
            }
        }
        
        headerData.append(&header,  length: sizeof(UInt8.self))           // 1
        headerData.append(&version, length: sizeof(UInt8.self))           // 2
        headerData.append(&typesCount, length: sizeof(UInt8.self))        // 3
        headerData.append(&samplesPerSecond, length: sizeof(UInt8.self))  // 4
        headerData.append(&start, length: sizeof(Double.self))            // 12
        headerData.append(&sampleCount, length: sizeof(UInt32.self))      // 16
        headerData.append(&types, length: types.count)                    // 16 + 4 * |types|

        target.writeData(headerData as Data, offset: 0)
        target.close()
    }
    
    /// The duration encoded
    public var duration: TimeInterval? {
        if sampleCount > 0 {
            return Double(sampleCount - 1) / Double(samplesPerSecond)
        }
        return nil
    }
    
    /// The end date of the encoder
    public var endDate: Date? {
        if let duration = duration, start = startDate {
            return start.addingTimeInterval(duration)
        }
        return nil
    }
    
}
