import UIKit
import MuvrKit

///
/// Labels in-session explicit exercise
///
class MRLabellingViewController : UIViewController {

    @IBOutlet weak var reps: UITextField!
    @IBOutlet weak var weight: UITextField!
    @IBOutlet weak var intensity: UISlider!
    
    weak var session: MRManagedExerciseSession!
    var exercise: MKIncompleteExercise!
    var start: NSDate!
    var duration: NSTimeInterval!
    
    override func viewDidAppear(animated: Bool) {
        let components = exercise.exerciseId.componentsSeparatedByString("/")
        title = components[components.count - 1]
    }
    
    @IBAction func onDone(sender: AnyObject) {
        let e = MRIncompleteExercise(
            exerciseId: exercise.exerciseId,
            repetitions: Int32(reps.text ?? "0"),
            intensity: Double(intensity.value),
            weight: Double(weight.text ?? "0"),
            confidence: 0)
        
        session.addLabel(e, start: start, duration: duration, inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
        MRAppDelegate.sharedDelegate().saveContext()
        
        performSegueWithIdentifier("exitLabelling", sender: self)
    }
    
}
