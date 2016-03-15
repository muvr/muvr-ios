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
        case ComingUp(exerciseDetail: MKExerciseDetail?)
        /// The user should get ready to start the given ``exercise``
        /// - parameter exerciseId: the exercise identity
        /// - parameter labels: the labels
        case Ready(exerciseDetail: MKExerciseDetail)
        /// The user is exercising
        /// - parameter exerciseId: the exercise identity
        /// - parameter labels: the labels
        /// - parameter start: the start date
        case InExercise(exerciseDetail: MKExerciseDetail, start: NSDate)
        /// The user has finished exercising
        /// - parameter exerciseId: the exercise identity
        /// - parameter labels: the labels
        /// - parameter start: the start date
        /// - parameter duration: the duration
        case Done(exerciseDetail: MKExerciseDetail, labels: [MKExerciseLabel], start: NSDate, duration: NSTimeInterval)
        
        var color: UIColor {
            switch self {
            case .ComingUp: return UIColor.greenColor()
            case .Ready: return UIColor.orangeColor()
            case .InExercise: return UIColor.redColor()
            case .Done: return UIColor.grayColor()
            }
        }
        
    }
    
    /// The circle that displays an exercise and a round bar
    @IBOutlet private weak var mainExerciseView: MRCircleExerciseView!
    
    /// The session–in–progress
    private var session: MRManagedExerciseSession!
    /// The current state
    private var state: State = .ComingUp(exerciseDetail: nil)
    
    /// The details view controllers
    private var comingUpViewController: MRSessionComingUpViewController!
    private var readyViewController: UIViewController!
    private var inExerciseViewController: UIViewController!
    private var labellingViewController: MRSessionLabellingViewController!
    
    private var comingUpExerciseDetails: [MKExerciseDetail] = []
    
    /// The list of alternatives exercises
    private var alternatives: [MKExerciseDetail] {
        guard case .ComingUp(let ed) = state, let selected = ed ?? comingUpExerciseDetails.first else { return [] }
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
        let ed = mainExerciseView.exerciseDetail
        let expectedLabels = ed?.labels.filter { $0 != .Intensity } ?? []
        let predictedLabels = ed.map(session.predictExerciseLabelsForExerciseDetail)?.0 ?? []
        if predictedLabels.count >= expectedLabels.count {
            mainExerciseView.exerciseLabels = predictedLabels
            mainExerciseView.exerciseDuration = ed.flatMap(session.predictDurationForExerciseDetail)
        } else {
            mainExerciseView.exerciseLabels = nil
            mainExerciseView.exerciseDuration = nil
        }
    }
    
    ///
    /// Updates the main title and the detail controller according the ``state``.
    /// - parameter state: the state to be displayed
    ///
    private func refreshViewsForState(state: State) {
        mainExerciseView.progressFullColor = state.color
        switch state {
        case .ComingUp(let exerciseDetail):
            comingUpExerciseDetails = session.exerciseDetailsComingUp
            let ed = exerciseDetail ?? comingUpExerciseDetails.first
            mainExerciseView.headerTitle = "Coming up".localized()
            mainExerciseView.exerciseDetail = ed
            mainExerciseView.swipeButtonsHidden = alternatives.count < 2
            showPredictedLabels()
            mainExerciseView.reset()
            mainExerciseView.start(session.predictRestDuration())
            switchToViewController(comingUpViewController, fromRight: exerciseDetail == nil) {
                self.mainExerciseView.swipeButtonsHidden = self.alternatives.count < 2
            }
            comingUpViewController.setExerciseDetails(comingUpExerciseDetails, onSelected: selectedExerciseDetail)
        case .Ready:
            mainExerciseView.headerTitle = "Get ready for".localized()
            mainExerciseView.swipeButtonsHidden = true
            mainExerciseView.reset()
            mainExerciseView.start(5)
            switchToViewController(readyViewController)
        case .InExercise(let exerciseDetail, _):
            mainExerciseView.headerTitle = "Stop".localized()
            mainExerciseView.reset()
            mainExerciseView.start(session.predictDurationForExerciseDetail(exerciseDetail) ?? session.defaultDurationForExerciseDetail(exerciseDetail))
            switchToViewController(inExerciseViewController)
        case .Done(let exerciseDetail, _, _, _):
            mainExerciseView.headerTitle = "Finished".localized()
            mainExerciseView.reset()
            mainExerciseView.start(15)
            switchToViewController(labellingViewController)
            let (predictedLabels, missingLabels) = session.predictExerciseLabelsForExerciseDetail(exerciseDetail)
            labellingViewController.setExerciseDetail(exerciseDetail, predictedLabels: predictedLabels, missingLabels: missingLabels, onLabelsUpdated: labelUpdated)
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
        if case .Done(let exerciseDetail, _, let start, let duration) = state {
            state = .Done(exerciseDetail: exerciseDetail, labels: newLabels, start: start, duration: duration)
        }
    }
    
    /// Called when an exercise is selected
    /// - parameter exercise: the selected exercise
    private func selectedExerciseDetail(selectedExerciseDetail: MKExerciseDetail) {
        mainExerciseView.exerciseDetail = selectedExerciseDetail
        showPredictedLabels()
        state = .ComingUp(exerciseDetail: selectedExerciseDetail)
        mainExerciseView.swipeButtonsHidden = alternatives.isEmpty
    }
    
    // MARK: - MRCircleViewDelegate
    
    func circleViewLongTapped(exerciseView: MRCircleView) {
        if case .ComingUp = state {
            try! MRAppDelegate.sharedDelegate().endCurrentSession()
        }
    }
    
    func circleViewTapped(exerciseView: MRCircleView) {
        switch state {
        case .ComingUp:
            // The user has tapped on the exercise. Let's get ready
            state = .Ready(exerciseDetail: mainExerciseView.exerciseDetail!)
        case .Ready(let exerciseDetail):
            state = .ComingUp(exerciseDetail: exerciseDetail)
        case .InExercise(let exerciseDetail, let start):
            let (labels, missing) = session.predictExerciseLabelsForExerciseDetail(exerciseDetail)
            state = .Done(exerciseDetail: exerciseDetail, labels: labels + missing.filter { !labels.contains($0) } , start: start, duration: NSDate().timeIntervalSinceDate(start))
            session.clearClassificationHints()
        case .Done(let exerciseDetail, let labels, let start, let duration):
            // The user has completed the exercise, and accepted our labels
            session.addExerciseDetail(exerciseDetail, labels: labels, start: start, duration: duration)
            state = .ComingUp(exerciseDetail: nil)
        }
        refreshViewsForState(state)
    }
    
    func circleViewCircleDidComplete(exerciseView: MRCircleView) {
        switch state {
        case .ComingUp:
            // We've exhausted our rest time. Turn orange to give the user a kick.
            mainExerciseView.progressFullColor = MRColor.orange
        case .Ready(let exerciseDetail):
            // We've had the time to get ready. Now time to exercise.
            let (labels, _) = session.predictExerciseLabelsForExerciseDetail(exerciseDetail)
            session.setClassificationHint(exerciseDetail, labels: labels)
            state = .InExercise(exerciseDetail: exerciseDetail, start: NSDate())
            refreshViewsForState(state)
        case .Done(let exerciseDetail, let labels, let start, let duration):
            // The user has completed the exercise, modified our labels, and accepted.
            session.addExerciseDetail(exerciseDetail, labels: labels, start: start, duration: duration)
            state = .ComingUp(exerciseDetail: nil)
            refreshViewsForState(state)
        default: return
        }
    }
    
    func circleViewSwiped(exerciseView: MRCircleView, direction: UISwipeGestureRecognizerDirection) {
        guard case .ComingUp(let ed) = state, let selected = ed ?? comingUpExerciseDetails.first else { return }
        let index = alternatives.indexOf { selected.id == $0.id } ?? 0
        let length = alternatives.count
        
        func next() -> Int? {
            guard length > 0 else { return nil }
            if direction == .Left { return (index + 1) % length }
            if direction == .Right { return (index - 1 + length) % length }
            return nil
        }
        
        guard let n = next() else { return }
        print("Swipe \(index) -> \(n): \(selected.id) -> \(alternatives[n].id)")
        selectedExerciseDetail(alternatives[n])
    }
    
}
