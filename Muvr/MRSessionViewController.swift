import UIKit
import MuvrKit

class MRSessionViewController : UIViewController, UITableViewDataSource, MRExerciseStoreDelegate, MRLabelledExerciseDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    private var labelledExercises: [MKLabelledExercise] = []
    private var session: MKExerciseSession?
    var sessionId: String? {
        didSet {
            exerciseStoreChanged()
        }
    }

    func exerciseStoreChanged() {
        if let sessionId = sessionId {
            session = MRAppDelegate.sharedDelegate().getSessionById(sessionId)
        } else {
            session = MRAppDelegate.sharedDelegate().currentSession
        }
        
        if session == nil {
            navigationController?.popViewControllerAnimated(true)
        }
        
        if tableView != nil { tableView.reloadData() }
    }
    
    func share(data: NSData, fileName: String) {
        let documentsUrl = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        let fileUrl = NSURL(fileURLWithPath: documentsUrl).URLByAppendingPathComponent(fileName)
        if data.writeToURL(fileUrl, atomically: true) {
            let controller = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
            let excludedActivities = [UIActivityTypePostToTwitter, UIActivityTypePostToFacebook,
                UIActivityTypePostToWeibo, UIActivityTypeMessage, UIActivityTypeMail,
                UIActivityTypePrint, UIActivityTypeCopyToPasteboard,
                UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr,
                UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo]
            controller.excludedActivityTypes = excludedActivities
            
            presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    // MARK: Share & label
    @IBAction func shareRaw() {
//        if let data = session?.sensorData?.encode() {
//            share(data, fileName: "sensordata.raw")
//        }
    }
    
    @IBAction func shareCSV() {
//        if let data = session?.sensorData?.encodeAsCsv(labelledExercises: labelledExercises) {
//            share(data, fileName: "sensordata.csv")
//        }
    }
    
    @IBAction func label(sender: UIBarButtonItem) {
        performSegueWithIdentifier("label", sender: nil)
    }
    
    // MARK: MRLabelledExerciseDelegate
    func labelledExerciseDidAdd(labelledExercise: MKLabelledExercise) {
        labelledExercises.append(labelledExercise)
        tableView.reloadData()
    }

    // MARK: UIViewController
    override func viewDidAppear(animated: Bool) {
        MRAppDelegate.sharedDelegate().exerciseStoreDelegate = self
        exerciseStoreChanged()
    }
    
    override func viewDidDisappear(animated: Bool) {
        MRAppDelegate.sharedDelegate().exerciseStoreDelegate = nil
    }

    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Classified Exercises"
        case 1: return "Labels"
        default: return nil
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return session?.classifiedExercises.count ?? 0
        case 1: return labelledExercises.count
        default: return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, let row):
            let ce = session!.classifiedExercises[row]
            let cell = tableView.dequeueReusableCellWithIdentifier("classifiedExercise")!
            cell.textLabel!.text = ce.exerciseId
            return cell
        case (1, let row):
            let le = labelledExercises[row]
            let cell = tableView.dequeueReusableCellWithIdentifier("labelledExercise")!
            cell.textLabel!.text = le.exerciseId
            return cell

        default: fatalError("Fixme")
        }
    }
    
}
