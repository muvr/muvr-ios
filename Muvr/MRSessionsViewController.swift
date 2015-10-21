import UIKit

class MRSessionsViewController : UIViewController {
    
    @IBAction func showTrainingView(sender: AnyObject) {
        performSegueWithIdentifier("train", sender: nil)
    }
    
}
