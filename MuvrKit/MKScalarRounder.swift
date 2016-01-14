import Foundation

public protocol MKScalarRounder {

    func roundValue(value: Float, forExerciseId exerciseId: MKExerciseId) -> Float
    
}

public struct MKScalarRounderFunction {
    
    public static func roundMinMax(value: Float, minimum: Float, increment: Float, maximum: Float?) -> Float {
        if value < minimum { return minimum }
        for var weight: Float = minimum; weight < maximum ?? 999; weight += increment {
            let dcw = value - weight
            let dnw = value - (weight + increment)
            if dcw >= 0 && dnw <= 0 {
                // value is in range
                if abs(dcw) > abs(dnw) {
                    return weight + increment
                } else {
                    return weight
                }
            }
        }
        return value
    }
}

