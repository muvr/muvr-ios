import UIKit

class MRTrainViewController : UIViewController {

    override func viewDidLoad() {
        self.navigationItem.hidesBackButton = true
    }
    
    @IBAction func startStop(sender: UIButton) {
        if sender.tag == 0 {
            // start
            sender.tag = 1
            sender.tintColor = UIColor.whiteColor()
            sender.setTitle("Stop", forState: UIControlState.Normal)
            sender.backgroundColor = UIColor.redColor()
        } else {
            // stop
            sender.tag = 0
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
}
