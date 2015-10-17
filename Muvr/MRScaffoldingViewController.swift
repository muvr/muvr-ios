import Foundation
import WatchConnectivity
import MuvrKit

class MRScaffoldingViewController : UIViewController, WCSessionDelegate, UITextFieldDelegate  {
    @IBOutlet var tag: UITextField!
    @IBOutlet var log: UITextView!

    /// classifier for RT classification
    private var classifier: MKClassifier!
    
    /// accumulated sensor data
    private var sensorData: MKSensorData?

    /// batch session files
    private var sessionFiles: [NSURL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup the classifier
        let bundlePath = NSBundle.mainBundle().pathForResource("Models", ofType: "bundle")!
        let data = NSData(contentsOfFile: NSBundle(path: bundlePath)!.pathForResource("demo", ofType: "raw")!)!
        let model = MKExerciseModel(layerConfig: [1200, 250, 100, 3], weights: data,
            sensorDataTypes: [.Accelerometer(location: .LeftWrist)],
            exerciseIds: ["1", "2", "3"])
        classifier = MKClassifier(model: model)
        
        // setup watch communication
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
        sessionFiles.append(fileUrl)
        
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
    
    func session(session: WCSession, didReceiveMessageData messageData: NSData, replyHandler: (NSData) -> Void) {
        do {
            replyHandler("Ack".dataUsingEncoding(NSASCIIStringEncoding)!)

            let blockSensorData = try MKSensorData(decoding: messageData)
            if sensorData != nil {
                try sensorData!.append(blockSensorData)
            } else {
                sensorData = blockSensorData
            }
            
            let classified = try classifier.classify(block: sensorData!, maxResults: 5)
            dispatch_async(dispatch_get_main_queue(), {
                self.log.text = self.log.text + "\n~> \(self.sensorData!.duration): \(classified.first)"
            })
        } catch {
            dispatch_async(dispatch_get_main_queue(), {
                self.log.text = self.log.text + "\n\(error)"
            })
        }
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        replyHandler(["ack" : "bar"])

        switch (message["action"] as? String) ?? "" {
        case "begin-real-time":
            dispatch_async(dispatch_get_main_queue(), {
                self.log.text = self.log.text + "\nBegin RT"
            })

            return
        case "end-real-time":
            dispatch_async(dispatch_get_main_queue(), {
                self.log.text = self.log.text + "\nEnd RT"
            })
            sensorData = nil
        default:
            return
        }
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func clear(sender: AnyObject) {
        sessionFiles = []
        log.text = ""
    }
    
    @IBAction func share(sender: AnyObject) {
        if sessionFiles.count == 0 { return }
        
        let controller = UIActivityViewController(activityItems: sessionFiles, applicationActivities: nil)
        let excludedActivities = [UIActivityTypePostToTwitter, UIActivityTypePostToFacebook,
                                    UIActivityTypePostToWeibo,
                                    UIActivityTypeMessage, UIActivityTypeMail,
                                    UIActivityTypePrint, UIActivityTypeCopyToPasteboard,
                                    UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll,
                                    UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr,
                                    UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo];
        
        controller.excludedActivityTypes = excludedActivities;
        presentViewController(controller, animated: true, completion: nil)
    }
    
}