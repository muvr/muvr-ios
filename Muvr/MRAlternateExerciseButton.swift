import Foundation
import UIKit
import MuvrKit

///
/// Draws a button that displays the given exercise in a rounded button
///
class MRAlternateExerciseButton: UIButton {
    
    /// When set, update the button with the exercise's title
    var exercise: MKIncompleteExercise? = nil {
        didSet {
            setTitle(exercise?.title, forState: .Normal)
        }
    }
    
    override func layoutSubviews() {
        let radius = min(frame.width, frame.height) / 2
        let lineWidth = radius / 16

        layer.cornerRadius = radius
        layer.borderWidth = lineWidth
        layer.borderColor = UIColor.darkTextColor().CGColor
    }
    
}
