import Foundation
import MuvrKit

enum MRScalarExerciseLabelSettableError : ErrorType {
    case NotScalar
    case LabelNotSupported
}

protocol MRScalarExerciseLabelSettable {

    static func supports(exerciseLabel: MKExerciseLabel) -> Bool
    
    func setExerciseLabel(exerciseLabel: MKExerciseLabel) throws
    
}
