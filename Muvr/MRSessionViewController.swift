import UIKit
import MuvrKit

///
/// The session view controller displays the session in progress
///
class MRSessionViewController : UIViewController, MRExerciseViewDelegate {
    
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
    @IBOutlet private weak var mainExerciseView: MRExerciseView!
    
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
        case .ComingUp(let exerciseDetail):
            comingUpExerciseDetails = session.exerciseDetailsComingUp
            let ed = exerciseDetail ?? comingUpExerciseDetails.first
            mainExerciseView.headerTitle = "Coming up".localized()
            mainExerciseView.exerciseDetail = ed
            mainExerciseView.exerciseLabels = ed.map(session.predictExerciseLabelsForExerciseDetail)?.0
            mainExerciseView.exerciseDuration = ed.flatMap(session.predictDurationForExerciseDetail)
            mainExerciseView.reset()
            mainExerciseView.start(session.predictRestDuration())
            switchToViewController(comingUpViewController, fromRight: exerciseDetail == nil)
            comingUpViewController.setExerciseDetails(comingUpExerciseDetails, onSelected: selectedExerciseDetail)
        case .Ready:
            mainExerciseView.headerTitle = "Get ready for".localized()
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
        if case .Done(let exerciseDetail, _, let start, let duration) = state {
            state = .Done(exerciseDetail: exerciseDetail, labels: newLabels, start: start, duration: duration)
        }
    }
    
    /// Called when an exercise is selected
    /// - parameter exercise: the selected exercise
    private func selectedExerciseDetail(selectedExerciseDetail: MKExerciseDetail) {
        mainExerciseView.exerciseDetail = selectedExerciseDetail
        mainExerciseView.exerciseLabels = session.predictExerciseLabelsForExerciseDetail(selectedExerciseDetail).0
        if let duration = session.predictDurationForExerciseDetail(selectedExerciseDetail) {
            mainExerciseView.exerciseDuration = duration
        }
        state = .ComingUp(exerciseDetail: selectedExerciseDetail)
    }
    
    // MARK: - MRExerciseViewDelegate
    
    func exerciseViewLongTapped(exerciseView: MRExerciseView) {
        if case .ComingUp = state {
            try! MRAppDelegate.sharedDelegate().endCurrentSession()
        }
    }
    
    func exerciseViewTapped(exerciseView: MRExerciseView) {
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
    
    func exerciseViewCircleDidComplete(exerciseView: MRExerciseView) {
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
    
    func exerciseViewSwiped(exerciseView: MRExerciseView, direction: UISwipeGestureRecognizerDirection) {
        guard case .ComingUp(let ed) = state, let selected = ed ?? comingUpExerciseDetails.first else { return }
        let alternatives = comingUpExerciseDetails.filter { $0.isAlternativeOf(selected) }
        
        let index = alternatives.indexOf { selected.id == $0.id } ?? 0
        let length = alternatives.count
        
        func next() -> Int? {
            if direction == .Left { return (index + 1) % length }
            if direction == .Right { return (index - 1 + length) % length }
            return nil
        }
        
        guard let n = next() else { return }
        selectedExerciseDetail(alternatives[n])
    }
    
}
