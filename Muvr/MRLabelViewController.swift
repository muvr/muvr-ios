import UIKit
import MuvrKit

///
/// Implementations will receive exercise labels as they are added.
///
protocol MRLabelledExerciseDelegate {
    
    ///
    /// Called when a new exercise label is available.
    ///
    /// - parameter labelledExercise: the completed LE
    ///
    func labelledExerciseDidAdd(labelledExercise: MKLabelledExercise)
    
}

class MRLabelViewController : UIViewController {
    private var start: NSDate?
    
    @IBOutlet weak var exerciseId: UITextField!
    @IBOutlet weak var weight: UITextField!
    @IBOutlet weak var repetitions: UITextField!
    @IBOutlet weak var intensity: UISlider!

    override func viewDidLoad() {
        self.navigationItem.hidesBackButton = true
    }
    
    @IBAction func startStop(sender: UIButton) {
        func doStart() {
            // start
            start = NSDate()
            sender.tag = 1
            sender.tintColor = UIColor.whiteColor()
            sender.setTitle("Stop", forState: UIControlState.Normal)
            sender.backgroundColor = UIColor.redColor()
        }

        func doStop() -> MKLabelledExercise {
            // stop
            sender.tag = 0
            
            return MKLabelledExercise(exerciseId: exerciseId.text!, start: start!, end: NSDate(),
                    repetitions: repetitions.text.flatMap { UInt($0) },
                    intensity: MKExerciseIntensity(intensity.value / 10.0),
                    weight: weight.text.flatMap { Double($0) })
        }
        
        if sender.tag == 0 {
            doStart()
        } else {
            let le = doStop()
            
            // Dismiss if presented in a navigation stack
            if let n = self.navigationController?.viewControllers.count,
               let parent = self.navigationController?.viewControllers[n - 2] {
                
                if let sink = parent as? MRLabelledExerciseDelegate {
                    sink.labelledExerciseDidAdd(le)
                }
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
    }
}
