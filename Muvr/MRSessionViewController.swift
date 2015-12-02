import UIKit
import CoreData
import MuvrKit

///
/// This class shows the exercises of the displayed session.
/// To display a session, you must call the ``setSession(session:)`` method and provide a valid ``MRManagedExerciseSesssion``.
///
class MRSessionViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addLabelBtn: UIBarButtonItem!
    @IBOutlet weak var navbar: UINavigationBar!
    @IBOutlet var sessionBar: UINavigationItem!
    @IBOutlet weak var uploadCSV: UIBarButtonItem!
    
    private var dataWaitingSpinner: UIBarButtonItem?
    
    // the displayed session
    private var session: MRManagedExerciseSession?
    private var summaryExercises: [MRSummaryExercise] = []
    
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
    
    private func isLabelOn() -> Bool {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.boolForKey("muvrLabelExerciseData")
    }
    
    private func displayLabelSection() {
        if (isLabelOn()) {
            addLabelBtn.enabled = isSessionActive()
            addLabelBtn.tintColor = nil
            uploadCSV.enabled = true
            uploadCSV.tintColor = nil
        } else {
            addLabelBtn.enabled = false
            addLabelBtn.tintColor = UIColor.clearColor()
            uploadCSV.enabled = false
            uploadCSV.tintColor = UIColor.clearColor()
        }
    }
    
    private func isSessionActive() -> Bool {
        return session != nil && session?.end == nil
    }
    
    private func isSessionCompleted() -> Bool {
        return session != nil && session!.completed
    }
    
    private func isDataAwaiting() -> Bool {
        return session != nil && !session!.completed && NSDate().timeIntervalSinceDate(session!.start) < 24*60*60
    }
    
    private func updateIndexExercises() {
        guard session != nil else { return }
        var i = 0
        var j = 0
        while (i < session!.classifiedExercises.count && j < session!.labelledExercises.count) {
            let ce = session!.classifiedExercises.allObjects[i] as! MRManagedClassifiedExercise
            let le = session!.labelledExercises.allObjects[j] as! MRManagedLabelledExercise
            if (ce.start.compare(le.start) == NSComparisonResult.OrderedAscending) {
                // time of ce < time of le
                ce.indexView = i + j
                i += 1
            } else {
                le.indexView = i + j
                j += 1
            }
        }
        while (i < session!.classifiedExercises.count) {
            let ce = session!.classifiedExercises.allObjects[i] as! MRManagedClassifiedExercise
            ce.indexView = i+j
            i += 1
        }
        while (j < session!.labelledExercises.count) {
            let le = session!.labelledExercises.allObjects[j] as! MRManagedLabelledExercise
            le.indexView = i+j
            j += 1
        }
    }
    
    private func printExerciseIndex() {
        guard session != nil else { return }
        NSLog("ClassifiedExercise index:")
        session!.classifiedExercises.forEach {any in
            let exer = any as! MRManagedClassifiedExercise
            NSLog("\(exer.start.formatTime()) - \(exer.indexView)")
        }
        NSLog("LabelledExercise index:")
        session!.labelledExercises.forEach {any in
            let exer = any as! MRManagedLabelledExercise
            NSLog("\(exer.start.formatTime()) - \(exer.indexView)")
        }
    }
    
    private func aggregateClassifiedExercises() -> [MRSummaryExercise] {
        guard session != nil else { return []}
        var summaryExercises: [MRSummaryExercise] = []
        session?.classifiedExercises.forEach { element in
            let exercise = element as! MRManagedClassifiedExercise
            let existedExercises = summaryExercises.filter { summary in
                return summary.exerciseId == exercise.exerciseId
            }
            if existedExercises.count == 0 {
                let newExercises = MRSummaryExercise()
                newExercises.start = exercise.start
                newExercises.duration = exercise.duration
                newExercises.sets = 1
                newExercises.repetitions = (exercise.repetitions ?? 0).integerValue
                newExercises.exerciseId = exercise.exerciseId
                summaryExercises.append(newExercises)
            } else {
                existedExercises[0].duration = existedExercises[0].duration + exercise.duration
                existedExercises[0].sets = existedExercises[0].sets + 1
                existedExercises[0].repetitions = existedExercises[0].repetitions + (exercise.repetitions ?? 0).integerValue
            }
        }
        return summaryExercises
    }
    
    private func initView() {
        displayLabelSection()
        if isSessionCompleted() {
            summaryExercises = aggregateClassifiedExercises()
        }
        updateIndexExercises()
    }
    
    private func moveFocusToEndSession() {
        let delay = 0.1 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue(), {
            let size = self.numberOfExerciseRows()
            if size > 0 {
                let indexPath = NSIndexPath(forRow: 0, inSection: size-1)
                self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            }
        })
    }

    // MARK: UIViewController

    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        initView()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "update", name: NSManagedObjectContextDidSaveNotification, object: MRAppDelegate.sharedDelegate().managedObjectContext)
        if let objectId = session?.objectID {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionDidEnd", name: MRNotifications.CurrentSessionDidEnd.rawValue, object: objectId)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionDidComplete", name: MRNotifications.SessionDidComplete.rawValue, object: objectId)
        }
        tableView.reloadData()
        if isDataAwaiting() {
            moveFocusToEndSession()
        }
    }
    
    override func viewDidLoad() {
        tableView.delegate = self
        initView()
        addLabelBtn.enabled = isSessionActive()
        if let s = session {
            navbar.topItem!.title = "\(s.start.formatTime()) - \(s.exerciseModelId)"
        } else {
            navbar.topItem!.title = nil
        }
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
    }
    
    // MARK: Share & label
    
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
        if isSessionCompleted() && summaryExercises.count > 0 {
            return summaryExercises.count
        }
        let sizeCE = session?.classifiedExercises.count ?? 0
        let sizeLE = session?.labelledExercises.count ?? 0
        if (session == nil) {
            return 0
        } else if (isDataAwaiting()) {
            return sizeCE + sizeLE + 1
        } else {
            return sizeCE + sizeLE
        }
    }

    /// check if a given classified exercise match a labelled exercise
    private func matchLabel(ce: MRManagedClassifiedExercise) -> Bool? {
        guard let session = session where session.labelledExercises.count > 0 else {
            // no labels found in session -> nothing to check
            return nil
        }
        let match = session.labelledExercises.reduce(false) { result, le in
            guard let le = le as? MRManagedLabelledExercise where !result else { return result }
            let duration = le.end.timeIntervalSinceDate(le.start)
            let tolerance = 8.0
            let matchStart = abs(le.start.timeIntervalSinceDate(ce.start)) < tolerance / 2
            let matchDuration = abs(duration - ce.duration) < tolerance
            let matchLabel = le.exerciseId == ce.exerciseId
            return matchStart && matchDuration && matchLabel
        }
        return match
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return numberOfExerciseRows()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10.0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let position = indexPath.section
        let cell = tableView.dequeueReusableCellWithIdentifier("classifiedExercise", forIndexPath: indexPath) as! MRTableViewCell
        cell.startLabel.text = ""
        cell.exerciseIdLabel.text = ""
        cell.detailLabel.text = ""
        cell.durationLabel.text = ""
        cell.verifiedImgView.image = nil
        cell.layer.cornerRadius = 13.0

        if (isDataAwaiting() && position == numberOfExerciseRows() - 1) {
            // draw the waiting spinner for the last row
            let spinnerView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
            spinnerView.frame = CGRectMake(0, 0, 14, 14)
            spinnerView.color = UIColor.blackColor()
            cell.addSubview(spinnerView)
            spinnerView.startAnimating()
            spinnerView.center = CGPointMake(cell.frame.size.width / 2, 25)
            tableView.rowHeight = 50
            cell.layer.borderWidth = 0
            cell.layer.borderColor = nil
            cell.backgroundColor = nil
            return cell
        }
        if isSessionCompleted() && summaryExercises.count > 0 {
            let exercise = summaryExercises[position]
            cell.exerciseIdLabel.text = exercise.exerciseId
            cell.startLabel.text = exercise.start.formatTime()
            cell.durationLabel.text = "\(NSString(format: "%.0f", exercise.duration))s"
            cell.detailLabel.text = "SETS: \(exercise.sets) - REPS: \(exercise.repetitions)"
            cell.layer.borderWidth = 2
            cell.layer.borderColor = UIColor.blueColor().CGColor
            return cell
        }
        cell.layer.borderWidth = 2
        let filterCE = session!.classifiedExercises.filter {element in
            let exercise = element as! MRManagedClassifiedExercise
            return exercise.indexView == position
        }
        if filterCE.count > 0 {
            // display classified exercise
            let ce = filterCE[0] as! MRManagedClassifiedExercise
            cell.backgroundColor = UIColor.whiteColor()
            cell.startLabel.text = "\(ce.start.formatTime())"
            cell.exerciseIdLabel.text = ce.exerciseId
            let duration = "\(NSString(format: "%.0f", ce.duration))s"
            let repetitions = ce.repetitions.map { r in "x\(r)" } ?? ""
            cell.durationLabel.text = duration
            cell.detailLabel.text = "Repetition: \(repetitions)"
            tableView.rowHeight = 80
            
            cell.layer.borderColor = UIColor.blueColor().CGColor
            if let match = matchLabel(ce) {
                if (match) {
                    cell.layer.borderColor = UIColor.redColor().CGColor
                }
                cell.verifiedImgView.image = UIImage(named: match ? "tick" : "miss")
            } else {
                cell.verifiedImgView.image = nil
            }
            
            return cell
        } else {
            let filterLE = session!.labelledExercises.filter {element in
                let exercise = element as! MRManagedLabelledExercise
                return exercise.indexView == position
            }
            if filterLE.count == 0 {
                NSLog("SHOULD NEVER HAPPEN")
                return cell
            }
            // display labelled exercise
            let le = filterLE[0] as! MRManagedLabelledExercise
            cell.backgroundColor = UIColor.whiteColor()
            cell.startLabel.text = "\(le.start.formatTime())"
            cell.exerciseIdLabel.text = le.exerciseId
            let duration = "\(NSString(format: "%.0f", le.end.timeIntervalSince1970 - le.start.timeIntervalSince1970))s"
            let repetitions = "x\(le.repetitions)"
            cell.durationLabel.text = duration
            cell.detailLabel.text = "Repetition: \(repetitions)"
            tableView.rowHeight = 80
            
            cell.layer.borderColor = UIColor.grayColor().CGColor
            return cell
        }
    }
    
}
