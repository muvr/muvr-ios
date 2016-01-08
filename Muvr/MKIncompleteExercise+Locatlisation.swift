import Foundation
import MuvrKit

extension MKIncompleteExercise {
    
    var title: String {
        let components = exerciseId.componentsSeparatedByString("/")
        assert(components.count >= 3)
        return NSLocalizedString(components.last!, comment: "\(components.last!) exercise").localizedCapitalizedString
    }

}
