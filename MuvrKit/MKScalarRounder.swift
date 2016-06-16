import Foundation

/////
///// Provides mechanism to round a value (of some kind, think weight) for the 
///// given exercise. To help you with the implementation, consider using the 
///// functions in ``MKScalarRounderFunction``.
/////
//public protocol MKScalarRounder {
//
//    ///
//    /// Rounds the ``value`` for the ``exerciseId``.
//    /// - parameter value: the value to be rounded
//    /// - parameter exerciseId: the exercise identity
//    /// - returns: the rounded value
//    ///
//    func roundValue(value: Double, forExerciseId exerciseId: MKExercise.Id) -> Double
//    
//}

///
/// Provides functions that simplify implementation of ``MKScalarRounder``
///
public struct MKScalarRounderFunction {
    
    /// Inaccessible initializer
    private init() {
        
    }
    
    ///
    /// Rounds the ``value`` to be between ``minimum`` and ``maximum`` with ``increment``s
    /// - parameter value: the vaulue to be rounded
    /// - parameter minimum: the minimum value
    /// - parameter increment: the increment steps
    /// - parameter maximum: the maximum value
    /// - returns: rounded
    ///
    public static func roundMinMax(_ value: Double, minimum: Double, step: Double, maximum: Double?) -> Double {
        if value < minimum { return minimum }
        if let maximum = maximum where value >= maximum {
            return maximum
        }
        var weight: Double = minimum
        while weight < maximum ?? 999 {
            weight += step
            let dcw = value - weight
            let dnw = value - (weight + step)
            if dcw >= 0 && dnw <= 0 {
                // value is in range
                if abs(dcw) > abs(dnw) {
                    return weight + step
                } else {
                    return weight
                }
            }
        }
        return value
    }
}

