import UIKit
import MuvrKit

class MRSessionViewController : UIViewController, MRExerciseViewDelegate {
    
    enum State {
        case ComingUp
        case Ready(exercise: MKIncompleteExercise)
        case InExercise(exercise: MKIncompleteExercise, start: NSDate)
        case Done(exercise: MKIncompleteExercise, start: NSDate, duration: NSTimeInterval)
        
        var color: UIColor {
            switch self {
            case .ComingUp: return UIColor.greenColor()
            case .Ready: return UIColor.orangeColor()
            case .InExercise: return UIColor.redColor()
            case .Done: return UIColor.grayColor()
            }
        }
    }
    
    @IBOutlet weak var mainExerciseView: MRExerciseView!
    
    private var sessionNavigationController: UINavigationController? = nil
    private var session: MRManagedExerciseSession!
    private var state: State = .ComingUp
    
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
    
    func tapped() {
        switch state {
        case .ComingUp: state = .Ready(exercise: mainExerciseView.exercise!)
        case .Ready:
            state = .ComingUp
            sessionNavigationController?.topViewController?.performSegueWithIdentifier("exitReady", sender: session)
        case .InExercise(let exercise, let start): state = .Done(exercise: exercise, start: start, duration: NSDate().timeIntervalSinceDate(start))
        case .Done(let exercise, let start, let duration):
            saveExercise(exercise, start: start, duration: duration)
            state = .ComingUp
            sessionNavigationController?.topViewController?.performSegueWithIdentifier("exitLabelling", sender: session)
        }
        refresh()
    }
    
    func circleDidComplete() {
        switch state {
        case .ComingUp:
            mainExerciseView.progressFullColor = UIColor.orangeColor()
        case .Ready(let exercise):
            state = .InExercise(exercise: exercise, start: NSDate())
            refresh()
        case .Done(let exercise, let start, let duration):
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
