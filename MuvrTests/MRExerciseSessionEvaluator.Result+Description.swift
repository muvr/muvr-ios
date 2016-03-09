import Foundation
@testable import Muvr
@testable import MuvrKit

extension MRExerciseSessionEvaluator.Result {
 
    var description: String {
        let result = NSMutableString()
        var lastExerciseId: String = ""
        for (exerciseDetail, descriptor, expected, predicted) in scalarLabels {
            if exerciseDetail.id != lastExerciseId {
                result.appendString("\n")
                result.appendString("\(exerciseDetail.id):\n")
                lastExerciseId = exerciseDetail.id
            }
            if let predicted = predicted {
                if abs(predicted.scalar() - expected.scalar()) < 0.1 {
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
