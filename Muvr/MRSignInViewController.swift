import UIKit

class MRSignInViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    override func viewDidLoad() {
        if let user = MRAppDelegate.sharedDelegate().user {
            email.text = user.email
        }
        email.delegate = self
        password.delegate = self
    }
    
    func textFieldShouldReturn(textfield: UITextField) -> Bool {
        switch (textfield) {
        case email: password.becomeFirstResponder()
        default: login()
        }
        return false
    }
    
    
    @IBAction func signIn(sender: UIButton) {
        login()
    }
    
    private func login() {
        guard let email = email.text, password = password.text
            else {
                NSLog("Missing user information")
                return
        }
        MRAppDelegate.sharedDelegate().signInUser(email: email, password: password.md5())
    }
    
}
