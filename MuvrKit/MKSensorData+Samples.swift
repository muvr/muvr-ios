import Foundation

///
/// Adds functions that convert the data into more manageable forms
///
public extension MKSensorData {
    
    ///
    /// Simple triple
    ///
    public struct Triple : Equatable {
        /// the X coordinate
        public let x: Float
        /// the Y coordinate
        public let y: Float
        /// the Z coordinate
        public let z: Float
        
        ///
        /// Initializes this struct, assigning the values
        ///
        /// - parameter x: the x
        /// - parameter y: the y
        /// - parameter z: the z
        ///
        init(x: Float, y: Float, z: Float) {
            self.x = x
            self.y = y
            self.z = z
        }
    }
    
    ///
    /// Represents the data as column slices as (x, y, z)T
    ///
    public func samplesAsTriples() throws -> [Triple] {
        if dimension != 3 { throw MKSensorDataFailure.MismatchedDimension(expected: 3, actual: dimension) }
        
        let dimCount = self.samples.count / dimension
        // 1
        // dimCount
        //  x  y  z  x  y  z
        // (0, 1, 2, 3, 4, 5)
        return (0..<dimCount).map { di in
            let x = self.samples[3 * di]
            let y = self.samples[3 * di + 1]
            let z = self.samples[3 * di + 2]
            return Triple(x: x, y: y, z: z)
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

public func ==(lhs: MKSensorData.Triple, rhs: MKSensorData.Triple) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
}
