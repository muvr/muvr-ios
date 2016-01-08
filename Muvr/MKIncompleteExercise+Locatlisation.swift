import Foundation
import MuvrKit

extension MKIncompleteExercise {
    
    var title: String {
        let components = exerciseId.componentsSeparatedByString("/")
        return NSLocalizedString(components.last!, comment: "\(components.last!) exercise").localizedCapitalizedString
    }
    
}
