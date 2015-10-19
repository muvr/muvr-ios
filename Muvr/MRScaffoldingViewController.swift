import Foundation
import WatchConnectivity
import MuvrKit

class MRScaffoldingViewController : UIViewController, MKExerciseModelSource, MKSessionClassifierDelegate {
    @IBOutlet var log: UITextView!

    /// classifier for RT classification
    private var classifier: MKSessionClassifier!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        classifier = MKSessionClassifier(exerciseModelSource: self,
            delegate: self,
            unclassified: MRAppDelegate.sharedDelegate().connectivity.sessions)
        MRAppDelegate.sharedDelegate().connectivity.sensorDataConnectivityDelegate = classifier
        MRAppDelegate.sharedDelegate().connectivity.exerciseConnectivitySessionDelegate = classifier
    }
    
    func getExerciseModel(id id: MKExerciseModelId) -> MKExerciseModel {
        // setup the classifier
        let bundlePath = NSBundle.mainBundle().pathForResource("Models", ofType: "bundle")!
        let data = NSData(contentsOfFile: NSBundle(path: bundlePath)!.pathForResource("demo", ofType: "raw")!)!
        let model = MKExerciseModel(layerConfig: [1200, 250, 100, 3], weights: data,
            sensorDataTypes: [.Accelerometer(location: .LeftWrist)],
            exerciseIds: ["biceps-curl", "lateral-raise", "triceps-extension"],
            minimumDuration: 8)
        return model
    }

    func sessionClassifierDidClassify(session: MKExerciseSession) {
        log.text = log.text + "\nClassified: \(session.classifiedExercises)"
    }
    
    func sessionClassifierDidSummarise(session: MKExerciseSession) {
        log.text = log.text + "\nSummarized \(session)"
    }
    
    func sessionClassifierDidStart(session: MKExerciseSession) {
        log.text = log.text + "\nStarted \(session)"
    }
    
    @IBAction func clear(sender: AnyObject) {
        MRAppDelegate.sharedDelegate().connectivity.clear()
        log.text = ""
    }
    
    @IBAction func share(sender: AnyObject) {
        if let session = MRAppDelegate.sharedDelegate().connectivity.session {
            let files = session.sensorDataFiles
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
    
}