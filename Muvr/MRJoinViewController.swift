import UIKit

class MRJoinViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var firstname: UITextField!
    @IBOutlet weak var lastname: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    override func viewDidLoad() {
        firstname.delegate = self
        lastname.delegate = self
        email.delegate = self
        password.delegate = self
    }
    
    func textFieldShouldReturn(textfield: UITextField) -> Bool {
        NSLog("SHOULD RETURN")
        switch (textfield) {
            case firstname: lastname.becomeFirstResponder()
            case lastname: email.becomeFirstResponder()
            case email: password.becomeFirstResponder()
            default: saveUser()
        }
        return false
    }
    
    
    @IBAction func join(sender: UIButton) {
        saveUser()
    }
    
    private func saveUser() {
        guard let firstname = firstname.text, lastname = lastname.text, email = email.text, password = password.text
            else {
                NSLog("Missing user information")
                return
        }
        MRAppDelegate.sharedDelegate().registerUser(firstname: firstname, lastname: lastname, email: email, password: password.md5())
    }
    
}
