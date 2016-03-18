import UIKit
import MuvrKit

///
/// The session view controller displays the session in progress
///
class MRSessionViewController : UIViewController, MRCircleViewDelegate {
    
    /// The state this controller is in
    enum State {
        /// An exercise ``exericseId`` with the ``labels`` is next
        /// - parameter exerciseId: the exercise identity
        /// - parameter labels: the labels
        case ComingUp(rest: NSTimeInterval?)
        /// The user should get ready to start the given ``exercise``
        /// - parameter exerciseId: the exercise identity
        /// - parameter labels: the labels
        case Ready(rest: NSTimeInterval?)
        /// The user is exercising
        /// - parameter exerciseId: the exercise identity
        /// - parameter labels: the labels
        /// - parameter start: the start date
        case InExercise(start: NSDate)
        /// The user has finished exercising
        /// - parameter exerciseId: the exercise identity
        /// - parameter labels: the labels
        /// - parameter start: the start date
        /// - parameter duration: the duration
        case Done(labels: [MKExerciseLabel], start: NSDate, duration: NSTimeInterval)
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
    private var state: State = .ComingUp(rest: nil)
    
    /// The details view controllers
    private var comingUpViewController: MRSessionComingUpViewController!
    private var readyViewController: UIViewController!
    private var inExerciseViewController: UIViewController!
    private var labellingViewController: MRSessionLabellingViewController!
    
    private var comingUpExerciseDetails: [MKExerciseDetail] = []
    
    private var currentExercise: (MKExerciseDetail, MKExerciseLabelsWithDuration, MKExerciseLabelsWithDuration)? = nil
    
    /// The list of alternatives exercises
    private var alternatives: [MKExerciseDetail] {
        guard case .ComingUp = state, let selected = currentExercise?.0 ?? comingUpExerciseDetails.first else { return [] }
        let visibleExerciseIds = comingUpViewController.visibleExerciseDetails.map { $0.id }
        return comingUpExerciseDetails.filter { $0.isAlternativeOf(selected) && (selected.id == $0.id || !visibleExerciseIds.contains($0.id)) }
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
    /// Show the predicted labels and duration in the main exercise view.
    /// All expected labels must be predicted otherwise no labels are shown.
    ///
    private func showPredictedLabels() {
        mainExerciseView.exerciseLabels = currentExercise?.1.0
        mainExerciseView.exerciseDuration = currentExercise?.1.1
    }
    
    ///
    /// Updates the main title and the detail controller according the ``state``.
    /// - parameter state: the state to be displayed
    ///
    private func refreshViewsForState(state: State) {
        mainExerciseView.progressFullColor = state.color
        switch state {
        case .ComingUp(let rest):
            comingUpExerciseDetails = session.exerciseDetailsComingUp
            mainExerciseView.headerTitle = "Coming up".localized()
            selectedExerciseDetail(comingUpExerciseDetails.first!)
            mainExerciseView.reset()
            let restDuration = rest ?? 60
            mainExerciseView.start(max(5, restDuration - 5)) // remove the 5s of the get ready countdown from rest duration
            switchToViewController(comingUpViewController, fromRight: false) {
                self.mainExerciseView.swipeButtonsHidden = self.alternatives.count < 2
            }
            comingUpViewController.setExerciseDetails(comingUpExerciseDetails, onSelected: selectedExerciseDetail)
        case .Ready:
            mainExerciseView.headerTitle = "Get ready for".localized()
            mainExerciseView.swipeButtonsHidden = true
            mainExerciseView.reset()
            mainExerciseView.start(5)
            switchToViewController(readyViewController)
        case .InExercise:
            mainExerciseView.headerTitle = "Stop".localized()
            mainExerciseView.reset()
            mainExerciseView.start((currentExercise?.1.1 ?? currentExercise?.2.1)!)
            switchToViewController(inExerciseViewController)
        case .Done:
            mainExerciseView.headerTitle = "Finished".localized()
            mainExerciseView.reset()
            mainExerciseView.start(15)
            switchToViewController(labellingViewController)
            labellingViewController.setExerciseDetail(currentExercise!.0, predictedLabels: currentExercise!.1.0, missingLabels: currentExercise!.2.0, onLabelsUpdated: labelUpdated)
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
    private func switchToViewController(controller: UIViewController, fromRight: Bool = true, completion: (Void -> Void)? = nil) {
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
                    if let comp = completion where finished { comp() }
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
                    if let comp = completion where finished { comp() }
                }
            )
        }
    }
    
    /// Called when the label is updated by the subcontroller
    /// - parameter newExercise: the updated label
    private func labelUpdated(newLabels: [MKExerciseLabel]) {
        mainExerciseView.reset()
        if case .Done(_, let start, let duration) = state {
            state = .Done(labels: newLabels, start: start, duration: duration)
        }
    }
    
    /// Called when an exercise is selected
    /// - parameter exercise: the selected exercise
    private func selectedExerciseDetail(selectedExerciseDetail: MKExerciseDetail) {
        mainExerciseView.exerciseDetail = selectedExerciseDetail
        let (predicted, missing) = session.predictExerciseLabelsForExerciseDetail(selectedExerciseDetail)
        currentExercise = (selectedExerciseDetail, predicted, missing)
        showPredictedLabels()
        mainExerciseView.swipeButtonsHidden = alternatives.count < 2
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
        case .ComingUp(let rest):
            // The user has tapped on the exercise. Let's get ready
            state = .Ready(rest: rest)
        case .Ready(let rest):
            state = .ComingUp(rest: rest)
        case .InExercise(let start):
            state = .Done(labels: currentExercise!.1.0 + currentExercise!.2.0, start: start, duration: NSDate().timeIntervalSinceDate(start))
            session.clearClassificationHints()
        case .Done(let labels, let start, let duration):
            // The user has completed the exercise, and accepted our labels
            session.addExerciseDetail(currentExercise!.0, labels: labels, start: start, duration: duration)
            state = .ComingUp(rest: (currentExercise?.1.2 ?? currentExercise?.2.2))
            case .Idle: break
        }
        refreshViewsForState(state)
    }
    
    func circleViewCircleDidComplete(exerciseView: MRCircleView) {
        switch state {
        case .ComingUp:
            // We've exhausted our rest time. Turn orange to give the user a kick.
            mainExerciseView.progressFullColor = MRColor.orange
        case .Ready:
            // We've had the time to get ready. Now time to exercise.
            session.setClassificationHint(currentExercise!.0, labels: currentExercise!.1.0)
            state = .InExercise(start: NSDate())
            refreshViewsForState(state)
        case .Done(let labels, let start, let duration):
            // The user has completed the exercise, modified our labels, and accepted.
            session.addExerciseDetail(currentExercise!.0, labels: labels, start: start, duration: duration)
            state = .ComingUp(rest: currentExercise?.1.2 ?? currentExercise?.2.2)
            refreshViewsForState(state)
        default: return
        }
    }
    
    func circleViewSwiped(exerciseView: MRCircleView, direction: UISwipeGestureRecognizerDirection) {
        guard case .ComingUp = state, let selected = currentExercise?.0 ?? comingUpExerciseDetails.first else { return }
        
        let index = alternatives.indexOf { selected.id == $0.id } ?? 0
        let length = alternatives.count
        
        func next() -> Int? {
            guard length > 0 else { return nil }
            if direction == .Left { return (index + 1) % length }
            if direction == .Right { return (index - 1 + length) % length }
            return nil
        }
        
        guard let n = next() else { return }
        selectedExerciseDetail(alternatives[n])
    }
    
}
