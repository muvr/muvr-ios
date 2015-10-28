import UIKit
import CoreData
import MuvrKit

class MRSessionViewController : UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addLabelBtn: UIBarButtonItem!
    @IBOutlet weak var navbar: UINavigationBar!
    
    private var session: MRManagedExerciseSession?
    private var runningSession: Bool = false
    private var classifiedExercises = []
    private var labelledExercises = []
    
    var index: Int?
    
    func setSessionId(session: MRManagedExerciseSession, sessionIndex: Int) {
        self.session = session
        index = sessionIndex
        runningSession = MRAppDelegate.sharedDelegate().currentSession.map { s in s == session } ?? false
        classifiedExercises = (session.classifiedExercises.allObjects as! [MRManagedClassifiedExercise]).sort({ (a, b)  in
            b.isBefore(a)
        })
        labelledExercises = (session.classifiedExercises.allObjects as! [MRManagedClassifiedExercise]).sort({ (a, b)  in
            b.isBefore(a)
        })

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

    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "update", name: NSManagedObjectContextDidSaveNotification, object: MRAppDelegate.sharedDelegate().managedObjectContext)
        if let objectId = session?.objectID {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionDidEnd", name: MRNotifications.CurrentSessionDidEnd.rawValue, object: objectId)
        }
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        addLabelBtn.enabled = runningSession
        if let start = session?.startDate {
            navbar.topItem!.title = "\(start.formatTime()) - \(session!.exerciseModelId)"
        } else {
            navbar.topItem!.title = session?.exerciseModelId
        }
    }
    
    func update() {
        tableView.reloadData()
    }
    
    func sessionDidEnd() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: Share & label
    @IBAction func shareRaw() {
        if let data = session?.sensorData {
            share(data, fileName: "sensordata.raw")
        }
    }
    
    @IBAction func shareCSV() {
        if let data = session?.sensorData,
            let labelledExercises = session?.labelledExercises.allObjects as? [MRManagedLabelledExercise],
            let sensorData = try? MKSensorData(decoding: data) {
            let csvData = sensorData.encodeAsCsv(labelledExercises: labelledExercises)
            share(csvData, fileName: "sensordata.csv")
        }
    }
    
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
        case 1: return session?.labelledExercises.count ?? 0
        default: return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("classifiedExercise", forIndexPath: indexPath)
            let le = classifiedExercises[indexPath.row]
            cell.textLabel!.text = le.exerciseId
            cell.detailTextLabel!.text = "Weight \(le.weight), intensity \(le.intensity)"
            return cell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("labelledExercise", forIndexPath: indexPath)
            let le = labelledExercises[indexPath.row]
            cell.textLabel!.text = le.exerciseId
            cell.detailTextLabel!.text = "Weight \(le.weight), intensity \(le.intensity)"
            return cell
        default:
            fatalError()
        }
    }
    
}
