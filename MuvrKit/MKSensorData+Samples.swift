import Foundation

public extension MKSensorData {
    
    ///
    /// Represents the data as column slices as (x, y, z)T
    ///
    public func samplesAsTriples() throws -> [(Float, Float, Float)] {
        if dimension != 3 { throw MKSensorDataFailure.MismatchedDimension(expected: 3, actual: dimension) }
        
        let dimCount = self.samples.count / dimension
        return (0..<dimCount).map { di in
            let x = self.samples[dimCount * 1 + di]
            let y = self.samples[dimCount * 2 + di]
            let z = self.samples[dimCount * 3 + di]
            return (x, y, z)
        }
    }
    
    ///
    /// Returns the data as scalars
    ///
    public func samplesAsScalars() throws -> [Float] {
        if dimension != 1 { throw MKSensorDataFailure.MismatchedDimension(expected: 1, actual: dimension) }
        return samples;
    }

}
