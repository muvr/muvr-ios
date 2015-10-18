import Foundation
import WatchConnectivity
import MuvrKit

class MRScaffoldingViewController : UIViewController, MKSensorDataConnectivityDelegate {
    @IBOutlet var log: UITextView!

    /// classifier for RT classification
    private var classifier: MKClassifier!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MRAppDelegate.sharedDelegate().connectivity.setDataConnectivityDelegate(delegate: self, on: dispatch_get_main_queue())
        
        // setup the classifier
        let bundlePath = NSBundle.mainBundle().pathForResource("Models", ofType: "bundle")!
        let data = NSData(contentsOfFile: NSBundle(path: bundlePath)!.pathForResource("demo", ofType: "raw")!)!
        let model = MKExerciseModel(layerConfig: [1200, 250, 100, 3], weights: data,
            sensorDataTypes: [.Accelerometer(location: .LeftWrist)],
            exerciseIds: ["biceps-curl", "lateral-raise", "triceps-extension"],
            minimumDuration: 8)
        classifier = MKClassifier(model: model)
    }
    
    func sensorDataConnectivityDidReceiveSensorData(accumulated accumulated: MKSensorData, new: MKSensorData) {
        log.text = log.text + "\nReceived data."
        do {
            let classified = try classifier.classify(block: accumulated, maxResults: 10)
            log.text = log.text + "\nClassified \(classified)"
        } catch {
            log.text = log.text + "\n\(error)"
        }
    }
    
    @IBAction func clear(sender: AnyObject) {
        MRAppDelegate.sharedDelegate().connectivity.clear()
        log.text = ""
    }
    
    @IBAction func share(sender: AnyObject) {
        let files = MRAppDelegate.sharedDelegate().connectivity.getSensorDataFiles()
        if  files.count == 0 { return }
        
        let controller = UIActivityViewController(activityItems: files, applicationActivities: nil)
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