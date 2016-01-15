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
        case ComingUp(exerciseId: MKExercise.Id?, labels: [MKExerciseLabel])
        /// The user should get ready to start the given ``exercise``
        /// - parameter exerciseId: the exercise identity
        /// - parameter labels: the labels
        case Ready(exerciseId: MKExercise.Id, labels: [MKExerciseLabel])
        /// The user is exercising
        /// - parameter exerciseId: the exercise identity
        /// - parameter labels: the labels
        /// - parameter start: the start date
        case InExercise(exerciseId: MKExercise.Id, labels: [MKExerciseLabel], start: NSDate)
        /// The user has finished exercising
        /// - parameter exerciseId: the exercise identity
        /// - parameter labels: the labels
        /// - parameter start: the start date
        /// - parameter duration: the duration
        case Done(exerciseId: MKExercise.Id, labels: [MKExerciseLabel], start: NSDate, duration: NSTimeInterval)
        
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
    private var state: State = .ComingUp(exerciseId: nil, labels: [])
    
    /// The details view controllers
    private var comingUpViewController: MRSessionComingUpViewController!
    private var readyViewController: UIViewController!
    private var inExerciseViewController: UIViewController!
    private var labellingViewController: MRSessionLabellingViewController!
    
    ///
    /// Sets the session to be displayed by this controller
    /// - parameter session: the session
    ///
    func setSession(session: MRManagedExerciseSession) {
        self.session = session
    }
    
    override func viewDidLoad() {
        mainExerciseView.delegate = self

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
        case .ComingUp(let exerciseId, let exerciseLabels):
            mainExerciseView.headerTitle = "Coming up".localized()
            mainExerciseView.exerciseId = exerciseId ?? session.exercises.first
            mainExerciseView.exerciseLabels = exerciseLabels
            mainExerciseView.reset()
            mainExerciseView.start(60)
            switchToViewController(comingUpViewController, fromRight: exerciseId == nil)
            comingUpViewController.setExercises(session.exercises, onSelected: selectedExercise)
        case .Ready:
            mainExerciseView.headerTitle = "Get ready for".localized()
            mainExerciseView.reset()
            mainExerciseView.start(5)
            switchToViewController(readyViewController)
        case .InExercise:
            mainExerciseView.headerTitle = "Stop".localized()
            mainExerciseView.reset()
            mainExerciseView.start(60)
            switchToViewController(inExerciseViewController)
        case .Done:
            mainExerciseView.headerTitle = "Finished".localized()
            mainExerciseView.reset()
            mainExerciseView.start(15)
            switchToViewController(labellingViewController)
            // TODO: Use the classified exercise instead of the selected one.
            labellingViewController.setExerciseId(mainExerciseView.exerciseId!, onLabelsUpdated: labelUpdated)
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
        let y = mainExerciseView.frame.origin.y + mainExerciseView.frame.height + 8
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
        if case .Done(let exerciseId, _, let start, let duration) = state {
            state = .Done(exerciseId: exerciseId, labels: newLabels, start: start, duration: duration)
        }
    }
    
    /// Called when an exercise is selected
    /// - parameter exercise: the selected exercise
    private func selectedExercise(selectedExerciseId: MKExercise.Id) {
        // mainExerciseView.exercise = session.exerciseWithPredictions(selectedExercise)
    }
    
    // MARK: - MRExerciseViewDelegate
    
    func exerciseViewLongTapped(exerciseView: MRExerciseView) {
        if case .ComingUp = state {
            MRAppDelegate.sharedDelegate().endCurrentSession()
        }
    }
    
    func exerciseViewTapped(exerciseView: MRExerciseView) {
        switch state {
        case .ComingUp:
            // The user has tapped on the exercise. Let's get ready
            state = .Ready(exerciseId: mainExerciseView.exerciseId!, labels: mainExerciseView.exerciseLabels)
        case .Ready(let exerciseId, let labels):
            state = .ComingUp(exerciseId: exerciseId, labels: labels)
        case .InExercise(let exerciseId, let labels, let start):
            state = .Done(exerciseId: exerciseId, labels: labels, start: start, duration: NSDate().timeIntervalSinceDate(start))
            session.endExercising()
        case .Done(let exerciseId, let labels, let start, let duration):
            // The user has completed the exercise, and accepted our labels
            session.addExerciseId(exerciseId, labels: labels, start: start, duration: duration, inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
            state = .ComingUp(exerciseId: nil, labels: [])
        }
        refreshViewsForState(state)
    }
    
    func exerciseViewCircleDidComplete(exerciseView: MRExerciseView) {
        switch state {
        case .ComingUp:
            // We've exhausted our rest time. Turn orange to give the user a kick.
            mainExerciseView.progressFullColor = UIColor.orangeColor()
        case .Ready(let exerciseId, let labels):
            // We've had the time to get ready. Now time to exercise.
            session.beginExercising(exerciseId, labels: labels)
            state = .InExercise(exerciseId: exerciseId, labels: labels, start: NSDate())
            refreshViewsForState(state)
        case .Done(let exerciseId, let labels, let start, let duration):
            // The user has completed the exercise, modified our labels, and accepted.
            session.addExerciseId(exerciseId, labels: labels, start: start, duration: duration, inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
            state = .ComingUp(exerciseId: nil, labels: [])
            refreshViewsForState(state)
        default: return
        }
    }
    
}
