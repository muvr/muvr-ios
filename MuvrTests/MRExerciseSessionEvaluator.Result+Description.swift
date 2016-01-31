import Foundation
@testable import Muvr
@testable import MuvrKit

extension MRExerciseSessionEvaluator.Result {
 
    var description: String {
        let result = NSMutableString()
        var lastExerciseId: String = ""
        for (exerciseId, descriptor, expected, predicted) in scalarLabels {
            if exerciseId != lastExerciseId {
                result.appendString("\n")
                result.appendString("\(exerciseId):\n")
                lastExerciseId = exerciseId
            }
            if let predicted = predicted {
                if abs(predicted - expected) < 0.1 {
                    result.appendString("  ✓ \(descriptor.id): predicted: \(predicted), actual: \(expected)\n")
                } else {
                    result.appendString("  ✗ \(descriptor.id): predicted: \(predicted), actual: \(expected)\n")
                }
            } else {
                result.appendString("  ✗ \(descriptor.id): predicted: (none), actual: \(expected)\n")
            }
        }
        return result as String
    }
    
}
