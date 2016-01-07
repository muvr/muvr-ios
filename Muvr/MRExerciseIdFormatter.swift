import Foundation
import MuvrKit

struct MRExerciseIdFormatter {
    
    enum MRExerciseIdFormatStyle {
        case Long
        case Short
    }

    let style: MRExerciseIdFormatStyle
    
    func format(exerciseId: MKExerciseId) -> String {
        let components = exerciseId.componentsSeparatedByString("/")
        switch (style) {
        case .Short: return NSLocalizedString(components.last!, comment: "\(components.last!) exercise")
        case .Long:
            return String.localizedStringWithFormat(
                NSLocalizedString("%@ - %@", comment: "exercise with group format"),
                NSLocalizedString(components.first!, comment: "\(components.first!) exercise group"),
                NSLocalizedString(components.last!, comment: "\(components.last!) exercise"))
        }
    }
}
