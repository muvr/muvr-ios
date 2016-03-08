import UIKit

@IBDesignable
class MRAlternateWorkoutButton: MRAlternativeButton {

    var session: MRSessionType? = nil {
        didSet {
            let title = session.map { $0.name }
            accessibilityLabel = title
            accessibilityHint = "Workout".localized()
            setTitle(title, forState: .Normal)
        }
    }
    
}