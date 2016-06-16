import Foundation
import UIKit
import MuvrKit

///
/// Draws a button that displays the given exercise in a rounded button
///
class MRAlternativeExerciseButton: MRAlternativeButton {
    
    /// The exercise detail displayed in this button
    var exerciseDetail: MKExerciseDetail? = nil {
        didSet {
            let title = exerciseDetail.map { MKExercise.title($0.id) }
            accessibilityLabel = title
            accessibilityHint = "Alternative".localized()
            setTitle(title, for: [])
        }
    }
    
}
