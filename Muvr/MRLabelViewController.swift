import UIKit
import MuvrKit

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
            fatalError()

//            return MKLabelledExercise(exerciseId: exerciseId.text!, start: start!, end: NSDate(),
//                    repetitions: repetitions.text.flatMap { UInt($0) },
//                    intensity: MKExerciseIntensity(intensity.value / 10.0),
//                    weight: weight.text.flatMap { Double($0) })
        }
        
        if sender.tag == 0 {
            doStart()
        } else {
            let le = doStop()
            
            // Dismiss if presented in a navigation stack
            if let n = self.navigationController?.viewControllers.count,
               let parent = self.navigationController?.viewControllers[n - 2] {
                
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
    }
}
