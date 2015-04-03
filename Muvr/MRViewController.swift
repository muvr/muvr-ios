import UIKit

class MRViewController: UIViewController, MRExerciseBlockDelegate {
    let preclassification: MRPreclassification = MRPreclassification()
    @IBOutlet var exercisingView: UIImageView!

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        exercisingView.hidden = true
    }
    
    @IBAction
    func start() {
        
    }
    
    @IBAction
    func stop() {
        
    }
    
    // MARK: MRExerciseBlockDelegate implementation
    
    func exerciseBlockEnded() {
        exercisingView.hidden = true
    }
    
    func exerciseBlockStarted() {
        exercisingView.hidden = false
    }

}

