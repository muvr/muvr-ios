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
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        timedView.textTransform = { _ in return "go!" }
        timedView.setColourScheme(MRColourSchemes.green)
        timedView.elapsedResets = false
        timedView.countingStyle = MRTimedView.CountingStyle.Elapsed
        tableView.registerNib(MRExerciseSetTableViewCell.nib, forCellReuseIdentifier: MRExerciseSetTableViewCell.cellReuseIdentifier)
    }

    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        timedView.setColourScheme(MRColourSchemes.green)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "update", name: NSManagedObjectContextDidSaveNotification, object: MRAppDelegate.sharedDelegate().managedObjectContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "locationDidObtain:", name: MRNotifications.LocationDidObtain.rawValue, object: nil)
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
    
    ///
    /// Local notification callback function intended to be used when location is set.
    /// - parameter notification: the details of the local notification
    ///
    func locationDidObtain(notification: NSNotification) {
        guard let exerciseModelId = session?.exerciseModelId else { return }
        
        if let locationName = notification.object as? String {
            title = "\(exerciseModelId) at \(locationName)"
        } else {
            title = exerciseModelId
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
