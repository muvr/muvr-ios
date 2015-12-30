import UIKit
import CoreData
import MuvrKit

///
/// This class shows the exercises of the displayed session.
/// To display a session, you must call the ``setSession(session:)`` method and provide a valid ``MRManagedExerciseSesssion``.
///
class MRSessionViewController : UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var labelButton: MRTimedButton!
    @IBOutlet weak var labelView: UIView!
    
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
    
    override func viewDidLoad() {
        tableView.registerNib(MRExerciseSetTableViewCell.nib, forCellReuseIdentifier: MRExerciseSetTableViewCell.cellReuseIdentifier)
    }

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
        if let session = session where !session.completed && NSDate().timeIntervalSinceDate(session.start) < 24*60*60 {
            labelView.hidden = false
        }
    }
    
    // MARK: notification callbacks
    
    func update() {
        tableView.reloadData()
    }
    
    func sessionDidEnd() {
        labelView.hidden = true
    }
    
    func sessionDidComplete() {
        labelView.hidden = true
    }
    
    // MARK: Share & label
    
    /// share the CSV session data
//    @IBAction func shareCSV() {
//        guard let session = session else { return }
//        
//        // make sure to keep a ref to the share Btn
//        let shareBtn = shareCSVBtn
//        MRAppDelegate.sharedDelegate().sessionStore.uploadSession(session) {
//            NSLog("SESSION UPLOADED")
//            dispatch_async(dispatch_get_main_queue(), {
//                self.shareCSVBtn = shareBtn
//                self.sessionBar.setRightBarButtonItems([self.addLabelBtn, self.shareCSVBtn], animated: false)
//            })
//        }
//    }
    
    /// display the ``Add label`` screen
    @IBAction func label(sender: UIBarButtonItem) {
        performSegueWithIdentifier("label", sender: session)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let lc = segue.destinationViewController as? MRLabelViewController, let session = sender as? MRManagedExerciseSession {
            lc.session = session
        }
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return session?.sets.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let set = session!.sets[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(MRExerciseSetTableViewCell.cellReuseIdentifier, forIndexPath: indexPath) as! MRExerciseSetTableViewCell
        cell.setSet(set)
        return cell
//        switch indexPath.section {
//        case 0:
//            let cell = tableView.dequeueReusableCellWithIdentifier("classifiedExercise", forIndexPath: indexPath)
//            let ce = session!.classifiedExercises.reverse()[indexPath.row] as! MRManagedClassifiedExercise
//            cell.textLabel!.text = ce.exerciseId
//            let weight = ce.weight.map { w in "\(NSString(format: "%.2f", w)) kg" } ?? ""
//            let intensity = ce.intensity.map { i in "Intensity: \(NSString(format: "%.2f", i))" } ?? ""
//            let duration = "\(NSString(format: "%.0f", ce.duration))s"
//            let repetitions = ce.repetitions.map { r in "x\(r)" } ?? ""
//            cell.detailTextLabel!.text = "\(ce.start.formatTime()) - \(duration) - \(repetitions) - \(weight) - \(intensity)"
//            guard let imageView = cell.viewWithTag(10) as? UIImageView else { return cell }
//            if let match = matchLabel(ce) {
//                imageView.image = UIImage(named: match ? "tick" : "miss")
//            } else {
//                imageView.image = nil
//            }
//            return cell
//        case 1:
//            let cell = tableView.dequeueReusableCellWithIdentifier("labelledExercise", forIndexPath: indexPath)
//            let le = session!.labelledExercises.reverse()[indexPath.row] as! MRManagedLabelledExercise
//            cell.textLabel!.text = le.exerciseId
//            let weight = "\(NSString(format: "%.2f", le.weight)) kg"
//            let intensity = "Intensity: \(NSString(format: "%.2f", le.intensity))"
//            let duration = "\(NSString(format: "%.0f", le.end.timeIntervalSince1970 - le.start.timeIntervalSince1970))s"
//            let repetitions = "x\(le.repetitions)"
//            cell.detailTextLabel!.text = "\(le.start.formatTime()) - \(duration) - \(repetitions) - \(weight) - \(intensity)"
//            return cell
//        default:
//            fatalError()
//        }
    }
    
}
