import UIKit
import MuvrKit

///
/// The session view controller displays the session in progress
///
class MRSessionViewController : UIViewController, MRCircleViewDelegate {
    
    /// The current selected exercise along with predicted labels
    private struct CurrentExercise {
        /// the selected exercise details
        let detail: MKExerciseDetail
        /// the predicted labels
        let predicted: MKExerciseLabelsWithDuration
        /// the default values for unpredicted labels
        let missing: MKExerciseLabelsWithDuration
        
        var labels: [MKExerciseLabel] {
            return predicted.0 + missing.0
        }
        
        var duration: NSTimeInterval? {
            return predicted.1 ?? missing.1
        }
        
        var rest: NSTimeInterval? {
            return predicted.2 ?? missing.2
        }
    }
    
    /// The state this controller is in
    private enum State {
        /// The user selects his next ``exercise``
        /// - parameter exercise: the selected exercise
        /// - parameter rest: the rest duration
        case ComingUp(exercise: CurrentExercise?, rest: NSTimeInterval?)
        /// The user should get ready to start the given ``exercise``
        /// - parameter exercise: the selected exercise
        /// - parameter rest: the rest duration
        case Ready(exercise: CurrentExercise, rest: NSTimeInterval?)
        /// The user is exercising
        /// - parameter exercise: the selected exercise
        /// - parameter start: the start date
        case InExercise(exercise: CurrentExercise, start: NSDate)
        /// The user has finished exercising
        /// - parameter exercise: the finished exercise
        /// - parameter labels: the labels
        /// - parameter start: the start date
        /// - parameter duration: the duration
        case Done(exercise: CurrentExercise, labels: [MKExerciseLabel], start: NSDate, duration: NSTimeInterval)
        /// The session is over (fix long press callback)
        case Idle
        
        var color: UIColor {
            switch self {
            case .ComingUp: return UIColor.greenColor()
            case .Ready: return UIColor.orangeColor()
            case .InExercise: return UIColor.redColor()
            case .Done: return UIColor.grayColor()
            case .Idle: return UIColor.clearColor()
            }
        }
        
    }
    
    /// The circle that displays an exercise and a round bar
    @IBOutlet private weak var mainExerciseView: MRCircleExerciseView!
    
    /// The session–in–progress
    private var session: MRManagedExerciseSession!
    /// The current state
    private var state: State = .ComingUp(exercise: nil, rest: nil)
    
    /// The details view controllers
    private var comingUpViewController: MRSessionComingUpViewController!
    private var readyViewController: UIViewController!
    private var inExerciseViewController: UIViewController!
    private var labellingViewController: MRSessionLabellingViewController!
    
    private var comingUpExerciseDetails: [MKExerciseDetail] = []
    
    /// The list of alternatives exercises
    private var alternatives: [MKExerciseDetail] {
        guard case .ComingUp(let currentExercise, _) = state, let selected = currentExercise?.detail ?? comingUpExerciseDetails.first else { return [] }
        return comingUpExerciseDetails.filter { $0.isAlternativeOf(selected) }
    }
    
    ///
    /// Sets the session to be displayed by this controller
    /// - parameter session: the session
    ///
    func setSession(session: MRManagedExerciseSession) {
        self.session = session
    }
    
    override func viewDidLoad() {
        mainExerciseView.delegate = self
        
        setTitleImage(named: "muvr_logo_white")
        navigationItem.setHidesBackButton(true, animated: false)
        
        UIView.appearanceWhenContainedInInstancesOfClasses([MRSessionViewController.self]).tintColor = MRColor.black
        
        comingUpViewController = storyboard!.instantiateViewControllerWithIdentifier("ComingUpViewController") as! MRSessionComingUpViewController
        readyViewController = storyboard!.instantiateViewControllerWithIdentifier("ReadyViewController")
        inExerciseViewController = storyboard!.instantiateViewControllerWithIdentifier("InExerciseViewController")
        labellingViewController = storyboard!.instantiateViewControllerWithIdentifier("LabellingViewController") as! MRSessionLabellingViewController
    }
    
    override func viewDidAppear(animated: Bool) {
        refreshViewsForState(state)
    }
    
    ///
    /// Updates the main title and the detail controller according the ``state``.
    /// - parameter state: the state to be displayed
    ///
    private func refreshViewsForState(state: State) {
        mainExerciseView.progressFullColor = state.color
        switch state {
        case .ComingUp(let exercise, let rest):
            comingUpExerciseDetails = session.exerciseDetailsComingUp
            mainExerciseView.headerTitle = "Coming up".localized()
            mainExerciseView.pickerHidden = false
            selectedExerciseDetail(exercise?.detail ?? comingUpExerciseDetails.first!)
            mainExerciseView.reset()
            let restDuration = rest ?? 60
            mainExerciseView.start(max(5, restDuration - 5)) // remove the 5s of the get ready countdown from rest duration
            switchToViewController(comingUpViewController, fromRight: exercise != nil)
            comingUpViewController.setExerciseDetails(comingUpExerciseDetails, onSelected: selectedExerciseDetail)
        case .Ready(let exercise, _):
            mainExerciseView.headerTitle = "Get ready for".localized()
            mainExerciseView.pickerHidden = true
            mainExerciseView.exerciseDetail = exercise.detail
            mainExerciseView.reset()
            mainExerciseView.start(5)
            switchToViewController(readyViewController)
        case .InExercise(let exercise, _):
            mainExerciseView.headerTitle = "Stop".localized()
            mainExerciseView.reset()
            mainExerciseView.start(exercise.duration!)
            switchToViewController(inExerciseViewController)
        case .Done(let exercise, _, _, _):
            mainExerciseView.headerTitle = "Finished".localized()
            mainExerciseView.reset()
            mainExerciseView.start(15)
            switchToViewController(labellingViewController)
            labellingViewController.setExerciseDetail(exercise.detail, predictedLabels: exercise.predicted.0, missingLabels: exercise.missing.0, onLabelsUpdated: labelUpdated)
        case .Idle: break;
        }
    }
    
    ///
    /// Show the given ``controller`` in the container pane; below the main button.
    /// The first controller appears from below.
    ///
    /// - parameter controller: the controller whose view is to be displayed in the container
    /// - parameter fromRight: true if the new controller appears from the right of the screen
    ///
    private func switchToViewController(controller: UIViewController, fromRight: Bool = true) {
        /// The frame where the details view are displayed (takes all available space below the main circle view)
        let y = mainExerciseView.frame.origin.y + mainExerciseView.frame.height
        let frame = CGRectMake(0, y, view.bounds.width, view.bounds.height - y)
        
        if let previousController = childViewControllers.first {
            let leftFrame = CGRectMake(-frame.width, frame.origin.y, frame.width, frame.height)
            let rightFrame = CGRectMake(frame.width, frame.origin.y, frame.width, frame.height)
            controller.view.frame = fromRight ? rightFrame : leftFrame
            
            addChildViewController(controller)
            previousController.willMoveToParentViewController(nil)
            
            transitionFromViewController(
                previousController,
                toViewController: controller,
                duration: 0.4,
                options: [],
                animations: {
                    controller.view.frame = frame
                    previousController.view.frame = fromRight ? leftFrame : rightFrame
                }, completion: { finished in
                    previousController.removeFromParentViewController()
                    controller.didMoveToParentViewController(self)
                }
            )
        } else {
            let belowFrame = CGRectMake(frame.origin.x, frame.origin.y + frame.height, frame.width, frame.height)
            addChildViewController(controller)
            controller.willMoveToParentViewController(self)
            controller.view.frame = belowFrame
            controller.beginAppearanceTransition(true, animated: true)
            view.addSubview(controller.view)
            UIView.animateWithDuration(0.2,
                animations: {
                    controller.view.frame = frame
                }, completion: { finished in
                    controller.didMoveToParentViewController(self)
                    controller.endAppearanceTransition()
                }
            )
        }
    }
    
    /// Called when the label is updated by the subcontroller
    /// - parameter newExercise: the updated label
    private func labelUpdated(newLabels: [MKExerciseLabel]) {
        mainExerciseView.reset()
        if case .Done(let exercise, _, let start, let duration) = state {
            state = .Done(exercise: exercise, labels: newLabels, start: start, duration: duration)
        }
    }
    
    /// Called when an exercise is selected
    /// - parameter exercise: the selected exercise
    private func selectedExerciseDetail(selectedExerciseDetail: MKExerciseDetail) {
        guard case .ComingUp(_, let rest) = state else { return }
        let (predicted, missing) = session.predictExerciseLabelsForExerciseDetail(selectedExerciseDetail)
        let currentExercise = CurrentExercise(detail: selectedExerciseDetail, predicted: predicted, missing: missing)
        state = .ComingUp(exercise: currentExercise, rest: rest)
        mainExerciseView.exerciseDetails = alternatives
        mainExerciseView.exerciseLabels = currentExercise.predicted.0
        mainExerciseView.exerciseDuration = currentExercise.predicted.1
        mainExerciseView.selectedIndex = alternatives.indexOf { selectedExerciseDetail.id == $0.id }
    }
    
    // MARK: - MRCircleViewDelegate
    
    func circleViewLongTapped(exerciseView: MRCircleView) {
        if case .ComingUp = state {
            try! MRAppDelegate.sharedDelegate().endCurrentSession()
            state = .Idle
        }
    }
    
    func circleViewTapped(exerciseView: MRCircleView) {
        switch state {
        case .ComingUp(let exercise, let rest):
            // The user has tapped on the exercise. Let's get ready
            state = .Ready(exercise: exercise!, rest: rest)
        case .Ready(let exercise, let rest):
            state = .ComingUp(exercise: exercise, rest: rest)
        case .InExercise(let exercise, let start):
            state = .Done(exercise: exercise, labels: exercise.labels, start: start, duration: NSDate().timeIntervalSinceDate(start))
            session.clearClassificationHints()
        case .Done(let exercise, let labels, let start, let duration):
            // The user has completed the exercise, and accepted our labels
            session.addExerciseDetail(exercise.detail, labels: labels, start: start, duration: duration)
            state = .ComingUp(exercise: nil, rest: exercise.rest)
            case .Idle: break
        }
        refreshViewsForState(state)
    }
    
    func circleViewCircleDidComplete(exerciseView: MRCircleView) {
        switch state {
        case .ComingUp:
            // We've exhausted our rest time. Turn orange to give the user a kick.
            mainExerciseView.progressFullColor = MRColor.orange
        case .Ready(let exercise, _):
            // We've had the time to get ready. Now time to exercise.
            session.setClassificationHint(exercise.detail, labels: exercise.predicted.0)
            state = .InExercise(exercise: exercise, start: NSDate())
            refreshViewsForState(state)
        case .Done(let exercise, let labels, let start, let duration):
            // The user has completed the exercise, modified our labels, and accepted.
            session.addExerciseDetail(exercise.detail, labels: labels, start: start, duration: duration)
            state = .ComingUp(exercise: nil, rest: exercise.rest)
            refreshViewsForState(state)
        default: return
        }
    }
    
    func circleSelectedIndexChanged(circleView: MRCircleView, index: Int) {
        guard case .ComingUp(_, let rest) = state else { return }
        let exerciseDetail = mainExerciseView.exerciseDetails[index]
        let (predicted, missing) = session.predictExerciseLabelsForExerciseDetail(exerciseDetail)
        let exercise = CurrentExercise(detail: exerciseDetail, predicted: predicted, missing: missing)
        mainExerciseView.exerciseLabels = predicted.0
        mainExerciseView.exerciseDuration = predicted.1
        state = .ComingUp(exercise: exercise, rest: rest)
    }
    
}
