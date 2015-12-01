import UIKit

class MRMenuViewController: UIViewController {
    
    @IBOutlet weak var username: UILabel!
    
    override func viewDidLoad() {
        if let user = MRAppDelegate.sharedDelegate().user {
            username.text = "\(user.firstname) \(user.lastname)"
        }
    }
    
    @IBAction func signOut(sender: UIButton) {
        MRAppDelegate.sharedDelegate().signOut()
    }
    
}
