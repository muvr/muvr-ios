import UIKit
import CoreData
import MuvrKit

///
/// This class shows the exercises of the displayed session.
/// To display a session, you must call the ``setSession(session:)`` method and provide a valid ``MRManagedExerciseSesssion``.
///
class MRSessionViewController : UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addLabelBtn: UIBarButtonItem!
    @IBOutlet weak var navbar: UINavigationBar!
    @IBOutlet var sessionBar: UINavigationItem!
    
    private var dataWaitingSpinner: UIBarButtonItem?
    
    // the displayed session
    private var session: MRManagedExerciseSession?
    // indicates if the displayed session is active (i.e. not finished)
    
    ///
    /// Provides the session to display
    ///
    func setSession(session: MRManagedExerciseSession) {
        self.session = session
    }
    
    ///
    /// Find an activity to share the give file
    ///
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
    
    // MARK: UIViewController

    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "update", name: NSManagedObjectContextDidSaveNotification, object: MRAppDelegate.sharedDelegate().managedObjectContext)
        if let objectId = session?.objectID {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionDidEnd", name: MRNotifications.CurrentSessionDidEnd.rawValue, object: objectId)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionDidComplete", name: MRNotifications.SessionDidComplete.rawValue, object: objectId)
        }
        tableView.reloadData()
        moveFocusToEndSession()
    }
    
    override func viewDidLoad() {
        addLabelBtn.enabled = session != nil && session?.end == nil
        if let s = session {
            navbar.topItem!.title = "\(s.start.formatTime()) - \(s.exerciseModelId)"
        } else {
            navbar.topItem!.title = nil
        }
    }
    
    private func moveFocusToEndSession() {
        let delay = 0.1 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue(), {
            let size = self.numberOfExerciseRows()
            if size > 0 {
                let indexPath = NSIndexPath(forRow: size-1, inSection: 0)
                self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            }
        })
    }
    
    func isDataAwaiting() -> Bool {
        return session != nil && !session!.completed && NSDate().timeIntervalSinceDate(session!.start) < 24*60*60
    }
    
    // MARK: notification callbacks
    
    func update() {
        tableView.reloadData()
        moveFocusToEndSession()
    }
    
    func sessionDidEnd() {
        addLabelBtn.enabled = false
    }
    
    func sessionDidComplete() {
        NSLog("session completed")
//        hideDataWaitingSpinner()
    }
    
    // MARK: Share & label
    
    /// share the raw session data
    @IBAction func shareRaw() {
        if let data = session?.sensorData,
            let sessionId = session?.id,
            let exerciseModel = session?.exerciseModelId {
            share(data, fileName: "\(exerciseModel)_\(sessionId).raw")
        }
    }
    
    /// share the CSV session data
    @IBAction func shareCSV() {
        if let data = session?.sensorData,
            let sessionId = session?.id,
            let labelledExercises = session?.labelledExercises.allObjects as? [MRManagedLabelledExercise],
            let exerciseModel = session?.exerciseModelId,
            let sensorData = try? MKSensorData(decoding: data) {
                let csvData = sensorData.encodeAsCsv(labelledExercises: labelledExercises)
                share(csvData, fileName: "\(exerciseModel)_\(sessionId).csv")
        }
    }
    
    /// display the ``Add label`` screen
    @IBAction func label(sender: UIBarButtonItem) {
        performSegueWithIdentifier("label", sender: session)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let lc = segue.destinationViewController as? MRLabelViewController, let session = sender as? MRManagedExerciseSession {
            lc.session = session
        }
    }
    
    func numberOfExerciseRows() -> Int {
        if (session == nil) {
            return 0
        } else if (isDataAwaiting()) {
            return (session?.classifiedExercises.count ?? 0) + 1   
        } else {
            return session?.classifiedExercises.count ?? 0
        }
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
        case 0: return numberOfExerciseRows()
        case 1: return session?.labelledExercises.count ?? 0
        default: return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("classifiedExercise", forIndexPath: indexPath) as! MRTableViewCell
            
            if (isDataAwaiting() && indexPath.row == numberOfExerciseRows() - 1) {
                // draw the waiting spinner for the last row
                
                cell.startLabel.text = ""
                cell.exerciseIdLabel.text = ""
                cell.detailLabel.text = ""
                cell.durationLabel.text = ""
                let spinnerView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
                spinnerView.frame = CGRectMake(0, 0, 14, 14)
                spinnerView.color = UIColor.blackColor()
                cell.addSubview(spinnerView)
                spinnerView.startAnimating()
                spinnerView.center = CGPointMake(cell.frame.size.width / 2, 25)
                tableView.rowHeight = 50
                return cell
            }
            cell.backgroundColor = UIColor.whiteColor()
            let ce = session!.classifiedExercises.allObjects[indexPath.row] as! MRManagedClassifiedExercise
            cell.startLabel.text = "\(ce.start.formatTime())"
            cell.exerciseIdLabel.text = ce.exerciseId
            let weightDouble = ce.weight?.doubleValue ?? 0.0
            let weight = "\(NSString(format: "%.2f", weightDouble)) kg"
            let intensityDouble = ce.intensity?.doubleValue ?? 0.0
            let intensity = "Intensity: \(NSString(format: "%.2f", intensityDouble))"
            let duration = "\(NSString(format: "%.0f", ce.duration))s"
            cell.durationLabel.text = duration
            cell.detailLabel.text = "\(weight) - \(intensity)"
            tableView.rowHeight = 80
            return cell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("labelledExercise", forIndexPath: indexPath)
            let le = session!.labelledExercises.reverse()[indexPath.row] as! MRManagedLabelledExercise
            cell.textLabel!.text = le.exerciseId
            let weight = "\(NSString(format: "%.2f", le.weight)) kg"
            let intensity = "Intensity: \(NSString(format: "%.2f", le.intensity))"
            let duration = "\(NSString(format: "%.0f", le.end.timeIntervalSince1970 - le.start.timeIntervalSince1970))s"
            cell.detailTextLabel!.text = "\(le.start.formatTime()) - \(duration) - \(weight) - \(intensity)"
            tableView.rowHeight = 50
            return cell
        default:
            fatalError()
        }
    }
    
}
