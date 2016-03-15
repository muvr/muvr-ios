import UIKit

///
/// A circle view to display a workout detail
///
class MRCircleWorkoutView: MRCircleView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityIdentifier = "Workout control"
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        accessibilityIdentifier = "Workout control"
    }
    
    ///
    /// The workout being displayed
    ///
    var sessionType: MRSessionType? {
        didSet {
            title = sessionType?.name
        }
    }
    
}
