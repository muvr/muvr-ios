import UIKit
import MuvrKit

class MRProfileViewController : UIViewController {
    
    @IBAction private func initialSetup() {
        MRAppDelegate.sharedDelegate().initialSetup()
    }
    
}
