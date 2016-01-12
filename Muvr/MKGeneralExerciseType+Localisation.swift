import Foundation
import MuvrKit

extension MKGeneralExerciseType {
    
    var title: String {
        return NSLocalizedString("MKExerciseType.\(id)", comment: id).localizedCapitalizedString
    }
    
}
