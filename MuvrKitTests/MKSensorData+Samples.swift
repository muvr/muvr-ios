import Foundation
@testable import MuvrKit

///
/// Adds functions that convert the data into more manageable forms
///
extension MKSensorData {
    
    ///
    /// Simple triple
    ///
    struct Triple : Equatable {
        /// the X coordinate
        let x: Float
        /// the Y coordinate
        let y: Float
        /// the Z coordinate
        let z: Float
        
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
    func samplesAsTriples(along type: MKSensorDataType) throws -> [Triple] {
        let bitmap = types.reduce([]) { r, t in
            return r + [Bool](count: t.dimension, repeatedValue: t == type)
        }
        let requestedDimension = bitmap.filter { $0 }.count
        if requestedDimension != 3 { throw MKSensorDataFailure.MismatchedDimension(expected: 3, actual: requestedDimension) }
        
        let rowCount = self.samples.count / dimension
        
        // 1
        // dimCount
        //  x  y  z  x  y  z
        // (0, 1, 2, 3, 4, 5)
        return (0..<rowCount).map { row in
            var result: [Float] = []
            for (idx, value) in bitmap.enumerate() {
                if value {
                    result.append(self.samples[row * dimension + idx])
                }
            }
            return Triple(x: result[0], y: result[1], z: result[2])
        }
    }
    
    ///
    /// Returns the data as scalars
    ///
    func samplesAsScalars(along type: MKSensorDataType) throws -> [Float] {
        let bitmap = types.reduce([]) { r, t in
            return r + [Bool](count: t.dimension, repeatedValue: t == type)
        }
        let requestedDimension = bitmap.filter { $0 }.count
        if requestedDimension != 1 { throw MKSensorDataFailure.MismatchedDimension(expected: 1, actual: requestedDimension) }
        
        return samples
    }

}

func ==(lhs: MKSensorData.Triple, rhs: MKSensorData.Triple) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
}
