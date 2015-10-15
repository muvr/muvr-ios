import Foundation
import WatchConnectivity
import MuvrKit

class MRScaffoldingViewController : UIViewController, WCSessionDelegate  {
    @IBOutlet var tag: UITextField!
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
        let suffix = String(counter) + "-" + (tag.text ?? "")
        let fileUrl = NSURL(fileURLWithPath: documentsUrl).URLByAppendingPathComponent("sensordata-\(suffix).raw")
        
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

}