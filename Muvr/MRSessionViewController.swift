import UIKit
import CoreData
import MuvrKit

///
/// This class shows the exercises of the displayed session.
/// To display a session, you must call the ``setSession(session:)`` method and provide a valid ``MRManagedExerciseSesssion``.
///
class MRSessionViewController : UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var timedView: MRTimedView!
    
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
        timedView.textTransform = { _ in return "go!" }
        timedView.setColourScheme(MRColourSchemes.green)
        timedView.countingStyle = MRTimedView.CountingStyle.Elapsed
        tableView.registerNib(MRExerciseSetTableViewCell.nib, forCellReuseIdentifier: MRExerciseSetTableViewCell.cellReuseIdentifier)
    }

    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        timedView.setColourScheme(MRColourSchemes.green)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "update", name: NSManagedObjectContextDidSaveNotification, object: MRAppDelegate.sharedDelegate().managedObjectContext)
        if let objectId = session?.objectID {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionDidEnd", name: MRNotifications.CurrentSessionDidEnd.rawValue, object: objectId)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionDidComplete", name: MRNotifications.SessionDidComplete.rawValue, object: objectId)
        }
        tableView.reloadData()
        if let session = session where !session.completed && NSDate().timeIntervalSinceDate(session.start) < 24*60*60 {
            timedView.hidden = false
            timedView.start(60) { $0.setColourScheme(MRColourSchemes.amber) }
            timedView.buttonTouched = timedViewButtonTouched
        } else {
            timedView.hidden = true
        }
    }
    
    private func timedViewButtonTouched(tv: MRTimedView) {
        performSegueWithIdentifier("exercise", sender: session)
    }
    
    // MARK: notification callbacks
    
    func update() {
        tableView.reloadData()
    }
    
    func sessionDidEnd() {
        timedView.hidden = true
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    func sessionDidComplete() {
        timedView.hidden = true
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if let lc = segue.destinationViewController as? MRLabelViewController, let session = sender as? MRManagedExerciseSession {
//            lc.session = session
//        }
        if let c = segue.destinationViewController as? MRExercisingViewController, let session = sender as? MRManagedExerciseSession {
            c.navigationItem.hidesBackButton = true
            c.session = session
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
    }
    
}
