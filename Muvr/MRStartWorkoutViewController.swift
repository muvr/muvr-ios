import UIKit
import MuvrKit

class MRStartWorkoutViewController: UIViewController {

    
    @IBOutlet weak var changeButton: UIButton!
    
    override func viewDidAppear(animated: Bool) {
        changeButton.titleLabel?.textAlignment = .Center
        changeButton.layer.cornerRadius = min(changeButton.frame.width, changeButton.frame.height) / 2
    }
    
}