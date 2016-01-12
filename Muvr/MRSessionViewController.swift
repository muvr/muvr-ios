import UIKit
import MuvrKit

///
/// The session view controller displays the session in progress
///
class MRSessionViewController : UIViewController, MRExerciseViewDelegate {
    
    /// The state this controller is in
    enum State {
        /// Some exercises are coming up
        case ComingUp
        /// The user should get ready to start the given ``exercise``
        /// - parameter exercise: the exercise the user selected
        case Ready(exercise: MKIncompleteExercise)
        /// The user is exercising
        /// - parameter exercise: the exercise in progress
        /// - parameter start: the start date
        case InExercise(exercise: MKIncompleteExercise, start: NSDate)
        /// The user has finished exercising
        /// - parameter exercise: the exercise
        /// - parameter start: the start date
        /// - parameter duration: the duration
        case Done(exercise: MKIncompleteExercise, start: NSDate, duration: NSTimeInterval)
        /// The user has finished
        // case Labelled(label: MKLabelledExercise)
        
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
    
    private var sessionNavigationController: UINavigationController? = nil
    /// The session–in–progress
    private var session: MRManagedExerciseSession!
    /// The current state
    private var state: State = .ComingUp
    
    ///
    /// Sets the session to be displayed by this controller
    /// - parameter session: the session
    ///
    func setSession(session: MRManagedExerciseSession) {
        self.session = session
    }
    
    override func viewDidLoad() {
        mainExerciseView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        refresh()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let controller = segue.destinationViewController as? UINavigationController {
            controller.navigationBarHidden = true
            sessionNavigationController = controller
        }
    }
    
    private func refresh() {
        mainExerciseView.progressFullColor = state.color
        switch state {
        case .ComingUp:
            mainExerciseView.headerTitle = "Coming up".localized()
            mainExerciseView.exercise = session.exercises.first
            mainExerciseView.reset()
            mainExerciseView.start(60)
            if let controller = sessionNavigationController?.topViewController as? MRSessionComingUpViewController {
                controller.setExercises(session.exercises) { self.mainExerciseView.exercise = $0 }
            }
        case .Ready:
            mainExerciseView.headerTitle = "Get ready for".localized()
            mainExerciseView.reset()
            mainExerciseView.start(5)
            sessionNavigationController?.topViewController?.performSegueWithIdentifier("ready", sender: session)
        case .InExercise:
            mainExerciseView.headerTitle = "Stop".localized()
            mainExerciseView.reset()
            mainExerciseView.start(60)
            sessionNavigationController?.topViewController?.performSegueWithIdentifier("exercising", sender: session)
        case .Done:
            mainExerciseView.headerTitle = "Finished".localized()
            mainExerciseView.reset()
            mainExerciseView.start(15)
            sessionNavigationController?.topViewController?.performSegueWithIdentifier("labelling", sender: session)
        }
    }
    
    private func saveExercise(exercise: MKIncompleteExercise, start: NSDate, duration: NSTimeInterval) {
        var ex: MKIncompleteExercise = exercise
        if let controller = sessionNavigationController?.topViewController as? MRSessionLabellingViewController {
            let intensity = controller.intensity
            let weight = controller.weight
            let reps = controller.repetitions.map { Int32($0) }
            ex = MRIncompleteExercise(exerciseId: exercise.exerciseId, repetitions: reps, intensity: intensity, weight: weight, confidence: 1)
        }
        session.addLabel(ex, start: start, duration: duration, inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
    }
    
    @IBAction func end() {
        MRAppDelegate.sharedDelegate().endCurrentSession()
    }
    
    private func labelChanged(exercise: MKIncompleteExercise) -> Bool {
        if let controller = sessionNavigationController?.topViewController as? MRSessionLabellingViewController {
            let intensity = controller.intensity
            let weight = controller.weight
            let reps = controller.repetitions.map { Int32($0) }
            return intensity != exercise.intensity ?? 0 || weight != exercise.weight ?? 0 || reps != exercise.repetitions ?? 0
        }
        return false
    }
    
    // MARK: - MRExerciseViewDelegate
    
    func exerciseViewLongTapped(exerciseView: MRExerciseView) {
        MRAppDelegate.sharedDelegate().endCurrentSession()
    }
    
    func exerciseViewTapped(exerciseView: MRExerciseView) {
        switch state {
        case .ComingUp:
            // The user has tapped on the exercise. Let's get ready
            state = .Ready(exercise: mainExerciseView.exercise!)
        case .Ready:
            state = .ComingUp
            sessionNavigationController?.topViewController?.performSegueWithIdentifier("exitReady", sender: session)
        case .InExercise(let exercise, let start):
            state = .Done(exercise: exercise, start: start, duration: NSDate().timeIntervalSinceDate(start))
        case .Done(let exercise, let start, let duration):
            saveExercise(exercise, start: start, duration: duration)
            state = .ComingUp
            sessionNavigationController?.topViewController?.performSegueWithIdentifier("exitLabelling", sender: session)
        }
        refresh()
    }
    
    func exerciseViewCircleDidComplete(exerciseView: MRExerciseView) {
        switch state {
        case .ComingUp:
            // We've exhausted our rest time. Turn orange to give the user a kick.
            mainExerciseView.progressFullColor = UIColor.orangeColor()
        case .Ready(let exercise):
            // We've had the time to get ready. Now time to exercise.
            state = .InExercise(exercise: exercise, start: NSDate())
            refresh()
        case .Done(let exercise, let start, let duration):
            // The user has completed the exercise.
            if !labelChanged(exercise) {
                // if something changed wait for user to press circle
                // otherwise save default values and move to next exercise
                saveExercise(exercise, start: start, duration: duration)
                state = .ComingUp
                sessionNavigationController?.topViewController?.performSegueWithIdentifier("exitLabelling", sender: session)
                refresh()
            }
        default: return
        }
    }
    
}
