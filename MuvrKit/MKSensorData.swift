import Foundation

public typealias MKTimestamp = Double
public typealias MKDuration = Double

///
/// Various failures that are thrown by the operations in the ``MKSensorData``
///
public enum MKSensorDataFailure : ErrorType {
    ///
    /// The dimensions do not match
    ///
    /// - parameter expected: the expected dimension count
    /// - parameter actual: the actual dimension count
    ///
    case MismatchedDimension(expected: Int, actual: Int)

    ///
    /// The sampling rates do not match
    ///
    /// - parameter expected: the expected sampling rate
    /// - parameter actual: the actual sampling rate
    ///
    case MismatchedSamplesPerSecond(expected: UInt, actual: UInt)
    
    ///
    /// The gap is too long to pad
    ///
    /// - parameter gap: the duration of the gap
    ///
    case TooDiscontinous(gap: MKDuration)
    
    ///
    /// The sample count does not match the expected count for the given dimensionality
    ///
    case InvalidSampleCountForDimension
}

public struct MKSensorData {
    /// The dimension of the samples; 1 for HR and such like, 3 for acceleraton, etc.
    let dimension: Int
    internal var samples: [Float]
    
    /// The samples per second
    let samplesPerSecond: UInt
    
    /// The start timestamp
    let start: MKTimestamp
    
    ///
    /// Constructs a new instance of this struct, assigns the dimension and samples
    ///
    public init(dimension: Int, start: MKTimestamp, samplesPerSecond: UInt, samples: [Float]) throws {
        if samples.count % dimension != 0 { throw MKSensorDataFailure.InvalidSampleCountForDimension }
        
        self.dimension = dimension
        self.samples = samples
        self.start = start
        self.samplesPerSecond = samplesPerSecond
    }

    ///
    /// Computes the end timestamp
    ///
    public var end: MKTimestamp {
        return start + Double(samples.count / dimension) / Double(samplesPerSecond)
    }
    
    ///
    /// Appends ``that`` to this by filling in the gaps or resolving the overlaps if necessary
    ///
    /// - parameter that: the MKSensorData of the same dimension and sampling rate to append
    ///
    mutating func append(that: MKSensorData) throws {
        // no need to add empty data
        if that.samples.isEmpty { return }
        if self.samplesPerSecond != that.samplesPerSecond { throw MKSensorDataFailure.MismatchedSamplesPerSecond(expected: self.samplesPerSecond, actual: that.samplesPerSecond) }
        if self.dimension != that.dimension { throw MKSensorDataFailure.MismatchedDimension(expected: self.dimension, actual: that.dimension) }
        
        let maxGap: MKDuration = 10
        let gap = that.start - self.end
    
        if gap > maxGap { throw MKSensorDataFailure.TooDiscontinous(gap: gap) }
        let samplesDelta = Int(gap * Double(samplesPerSecond)) * dimension
        
        if samplesDelta < 0 && -samplesDelta < samples.count {
            // partially overlapping
            let x: Int = samples.count + samplesDelta
            samples.removeRange(x..<samples.count)
            samples.appendContentsOf(that.samples)
        } else if samplesDelta < 0 && -samplesDelta == samples.count {
            // completely overlapping
            samples = that.samples
        } else if -samplesDelta > samples.count {
            // overshooting overlap
            fatalError("Implement me")
        } else if samplesDelta == 0 {
            // no gap; simply append
            samples.appendContentsOf(that.samples)
        } else /* if samplesDelta > 0 */ {
            // gapping
            var gapSamples = [Float](count: samplesDelta, repeatedValue: 0)
            for i in 0..<dimension {
                let selfDimCount = self.samples.count / dimension
                let thatDimCount = that.samples.count / dimension
                let gapDimCount  = gapSamples.count / dimension
                let last  = self.samples[selfDimCount * (i + 1) - 1]
                let first = that.samples[thatDimCount * i]
                let ds = Float(first - last) / Float(gapDimCount + 1)
                for j in 0..<gapDimCount {
                    gapSamples[gapDimCount * i + j] = last + ds * Float(j + 1)
                }
            }
            
            samples.appendContentsOf(gapSamples)
            samples.appendContentsOf(that.samples)
        }
    }
    
}
