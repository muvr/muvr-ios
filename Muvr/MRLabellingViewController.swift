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
        let exerciseName = exercise.exerciseId.componentsSeparatedByString("/").last ?? exercise.exerciseId
        title = exerciseName.capitalizedString
    }
    
    @IBAction func onDone(sender: AnyObject) {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        let e = MRIncompleteExercise(
            exerciseId: exercise.exerciseId,
            repetitions: formatter.numberFromString(reps.text ?? "0")?.intValue ?? 0,
            intensity: Double(intensity.value),
            weight: formatter.numberFromString(weight.text ?? "0")?.doubleValue ?? 0,
            confidence: 0)
        
        session.addLabel(e, start: start, duration: duration, inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
        MRAppDelegate.sharedDelegate().saveContext()
        
        performSegueWithIdentifier("exitLabelling", sender: self)
    }
    
}
