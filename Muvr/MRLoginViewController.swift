import Foundation

class MRLoginViewController : UIViewController {
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    
    private func showAccount(user: MRLoggedInApplicationState) {
        /*
        let deviceToken = (UIApplication.sharedApplication().delegate! as AppDelegate).deviceToken
        if deviceToken != nil {
            LiftServer.sharedInstance.userRegisterDeviceToken(user.id, deviceToken: deviceToken!)
        }
        CurrentLiftUser.userId = user.id
*/
        performSegueWithIdentifier("main", sender: nil)
    }
    
    @IBAction
    func login() {
        view.endEditing(true)
        MRApplicationState.login(email: username.text!, password: password.text!) { $0.getOrUnit(self.showAccount) }
    }
    
    @IBAction
    func register() {
        view.endEditing(true)
        MRApplicationState.register(email: username.text!, password: password.text!) { $0.getOrUnit(self.showAccount) }
    }
    
    @IBAction
    func skip() {
        view.endEditing(true)
        MRApplicationState.skip { $0.getOrUnit(self.showAccount) }
    }
}