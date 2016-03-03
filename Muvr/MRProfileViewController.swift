import UIKit
import MuvrKit

class MRProfileViewController : UIViewController {
    
    @IBAction private func initialSetup() {
        MRAppDelegate.sharedDelegate().initialSetup()
    }
    
    override func viewDidLoad() {
        setTitleImage(named: "muvr_logo_white")
    }
    
}
