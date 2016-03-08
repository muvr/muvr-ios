import Foundation
import UIKit
import MuvrKit

///
/// Draws a button that displays the given exercise in a rounded button
///
class MRAlternateExerciseButton: MRAlternativeButton {
    
    /// When set, update the button with the exercise's title
    var exerciseDetail: MKExerciseDetail? = nil {
        didSet {
            let title = exerciseDetail.map { MKExercise.title($0.0) }
            accessibilityLabel = title
            accessibilityHint = "Alternative".localized()
            setTitle(title, forState: .Normal)
        }
    }
    
}
