import UIKit
import MuvrKit

///
/// A circle view to display an exercise detail
///
class MRCircleExerciseView: MRCircleView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityIdentifier = "Exercise control"
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        accessibilityIdentifier = "Exercise control"
    }
    
    ///
    /// The exercise being displayed
    ///
    var exerciseDetail: MKExerciseDetail? {
        didSet {
            title = exerciseDetail.map { MKExercise.title($0.id) }
        }
    }
    
    ///
    /// The exercise 'predicted' labels for the displayed exercise
    ///
    var exerciseLabels: [MKExerciseLabel]? {
        didSet {
            createLabelViews()
        }
    }
    
    ///
    /// the exercise 'predicted' duration of the displayed exercise
    ///
    var exerciseDuration: NSTimeInterval? = nil {
        didSet {
            createLabelViews()
        }
    }
    
    ///
    /// create the labels view for the displayed exercise
    ///
    private func createLabelViews() {
        var views: [UIView] = []
        let frame = CGRectZero
        if let exerciseLabels = exerciseLabels {
            
            for exerciseLabel in exerciseLabels {
                let (view, _) = MRExerciseLabelViews.scalarViewForLabel(exerciseLabel, frame: frame)!
                views.append(view)
            }
        }
        
        if let duration = exerciseDuration {
            let view = MRExerciseLabelViews.scalarViewForDuration(duration, frame: frame)
            views.append(view)
        }
        labelViews = views
    }
    
}
