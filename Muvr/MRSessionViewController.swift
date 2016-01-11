import UIKit
import MuvrKit

class MRSessionViewController : UIViewController, MRExerciseViewDelegate {
    
    enum State {
        case Pick
        case Ready(exercise: MKIncompleteExercise)
        case InExercise(exercise: MKIncompleteExercise, start: NSDate)
        case Done(exercise: MKIncompleteExercise, start: NSDate, duration: NSTimeInterval)
        
        var color: UIColor {
            switch self {
            case .Pick: return UIColor.greenColor()
            case .Ready: return UIColor.orangeColor()
            case .InExercise: return UIColor.redColor()
            case .Done: return UIColor.grayColor()
            }
        }
    }
    
    @IBOutlet weak var mainExerciseView: MRExerciseView!
    private var session: MRManagedExerciseSession!
    private var state: State = .Pick
    
    func setSession(session: MRManagedExerciseSession) {
        self.session = session
    }
    
    override func viewDidLoad() {
        mainExerciseView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        refresh()
    }
    
    private func refresh() {
        mainExerciseView.progressFullColor = state.color
        switch state {
        case .Pick:
            mainExerciseView.headerTitle = "Coming up".localized()
            mainExerciseView.exercise = session.exercises.first
            mainExerciseView.reset()
            mainExerciseView.start(60)
        case .Ready:
            mainExerciseView.headerTitle = "Get ready for".localized()
            mainExerciseView.reset()
            mainExerciseView.start(5)
        case .InExercise:
            mainExerciseView.headerTitle = "Stop".localized()
            mainExerciseView.reset()
            mainExerciseView.start(60)
        case .Done:
            mainExerciseView.headerTitle = "Finished".localized()
            mainExerciseView.reset()
            mainExerciseView.start(15)
        }
    }
    
    private func saveExercise(exercise: MKIncompleteExercise, start: NSDate, duration: NSTimeInterval) {
        session.addLabel(exercise, start: start, duration: duration, inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
    }
    
    
    /// MARK : MRExerciseViewDelegate
    
    func tapped() {
        switch state {
        case .Pick: state = .Ready(exercise: mainExerciseView.exercise!)
        case .Ready: state = .Pick
        case .InExercise(let exercise, let start): state = .Done(exercise: exercise, start: start, duration: NSDate().timeIntervalSinceDate(start))
        case .Done(let exercise, let start, let duration):
            saveExercise(exercise, start: start, duration: duration)
            state = .Pick
        }
        refresh()
    }
    
    func circleDidComplete() {
        switch state {
        case .Pick:
            mainExerciseView.progressFullColor = UIColor.orangeColor()
        case .Ready(let exercise):
            state = .InExercise(exercise: exercise, start: NSDate())
            refresh()
        case .Done(let exercise, let start, let duration):
            saveExercise(exercise, start: start, duration: duration)
            state = .Pick
            refresh()
        default: return
        }
    }
    
}
