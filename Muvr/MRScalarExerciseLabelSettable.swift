import Foundation
import MuvrKit

enum MRScalarExerciseLabelSettableError : ErrorProtocol {
    case notScalar
    case labelNotSupported
}

protocol MRScalarExerciseLabelSettable {

    static func supports(_ exerciseLabel: MKExerciseLabel) -> Bool
    
    func setExerciseLabel(_ exerciseLabel: MKExerciseLabel) throws
    
}
