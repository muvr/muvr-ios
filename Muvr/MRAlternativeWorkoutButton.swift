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
            setTitle(title, for: UIControlState())
        }
    }
    
    /// True when the user has ``masterised`` this workout
    var achievement: String? {
        didSet {
            setImage(achievement.flatMap { UIImage(named: $0) }, for: UIControlState())
            setNeedsLayout()
        }
    }
}
