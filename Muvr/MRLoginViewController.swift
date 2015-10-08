import Foundation
import WatchConnectivity

class MRLoginViewController : UIViewController, WCSessionDelegate  {
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        WCSession.defaultSession().delegate = self
        WCSession.defaultSession().activateSession()
    }
    
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
    
    func session(session: WCSession, didReceiveMessageData messageData: NSData) {
        dispatch_async(dispatch_get_main_queue(), {
            self.username.text = __FUNCTION__
        })
    }
    
    func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        dispatch_async(dispatch_get_main_queue(), {
            self.username.text = __FUNCTION__
        })
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        dispatch_async(dispatch_get_main_queue(), {
            self.username.text = __FUNCTION__
        })
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        dispatch_async(dispatch_get_main_queue(), {
            self.username.text = __FUNCTION__
        })
    }
    
    func session(session: WCSession, didReceiveMessageData messageData: NSData, replyHandler: (NSData) -> Void) {
        dispatch_async(dispatch_get_main_queue(), {
            self.username.text = __FUNCTION__
        })
    }
    
    func sessionReachabilityDidChange(session: WCSession) {
        dispatch_async(dispatch_get_main_queue(), {
            self.username.text = __FUNCTION__
        })
    }
    
    func sessionWatchStateDidChange(session: WCSession) {
        username.text = __FUNCTION__
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