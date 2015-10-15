import Foundation
import WatchConnectivity
import MuvrKit

class MRLoginViewController : UIViewController, WCSessionDelegate  {
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var log: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        WCSession.defaultSession().delegate = self
        WCSession.defaultSession().activateSession()
    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        dispatch_async(dispatch_get_main_queue(), {
            self.log.text = self.log.text + "\n\(userInfo)"
        })
    }
    
    func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        let documentsUrl = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        let counter = NSDate().timeIntervalSince1970
        let fileUrl = NSURL(fileURLWithPath: documentsUrl).URLByAppendingPathComponent("sensordata-\(counter).raw")
        
        do {
            try NSFileManager.defaultManager().moveItemAtURL(file.fileURL, toURL: fileUrl)
            let sensorData = try MKSensorData(decoding: NSData(contentsOfURL: fileUrl)!)
            dispatch_async(dispatch_get_main_queue(), {
                self.log.text = self.log.text + "\n\(file.metadata!) for \(sensorData.duration)"
            })
        } catch {
            dispatch_async(dispatch_get_main_queue(), {
                self.log.text = self.log.text + "\n\(error)"
            })
        }
    }
    
    @IBAction
    func login() {
        view.endEditing(true)
        // TODO: Complete me
    }
    
    @IBAction
    func register() {
        view.endEditing(true)
        // TODO: Complete me
    }
    
    @IBAction
    func skip() {
        view.endEditing(true)
        
        performSegueWithIdentifier("main", sender: nil)
    }
}