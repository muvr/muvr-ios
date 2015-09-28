import Foundation
@testable import MuvrKit

///
/// Adds functions that convert the data into more manageable forms
///
extension MKSensorData {

    ///
    /// Returns the data as scalars
    ///
    func samplesAsScalars(along type: MKSensorDataType) throws -> [Float] {
        return samples(along: [type]).map { $0.first! }
    }

    ///
    /// Returns samples along the given types; this is essentially a column slice
    /// of the sensor data matrix
    ///
    /// - parameter types: the types that should be returned
    ///
    func samples(along types: [MKSensorDataType]) -> [[Float]] {
        let bitmap = self.types.reduce([]) { r, t in
            return r + [Bool](count: t.dimension, repeatedValue: types.contains(t))
        }
        let rowCount = self.samples.count / dimension
        return (0..<rowCount).map { row in
            return bitmap.enumerate().flatMap { (idx: Int, value: Bool) -> Float? in
                if value {
                    return self.samples[row * dimension + idx]
                }
                return nil
            }
        }
    }

}
