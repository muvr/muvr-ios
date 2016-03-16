import UIKit

@IBDesignable
///
/// Draws a button that displays the given session type in a rounded button
///
class MRAlternativeWorkoutButton: MRAlternativeButton {

    /// The session type displayed in this button
    var sessionType: MRSessionType? = nil {
        didSet {
            let title = sessionType?.name
            accessibilityLabel = title
            accessibilityHint = "Workout".localized()
            setTitle(title, forState: .Normal)
        }
    }
    
    /// True when the user has ``masterised`` this workout
    var achieved: Bool = false {
        didSet {
            let image = achieved ? UIImage(named: "star") : nil
            setImage(image, forState: .Normal)
            setNeedsLayout()
        }
    }
}