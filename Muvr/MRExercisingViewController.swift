import UIKit
import MuvrKit

///
/// Handles the in-session explicit exercise
///
class MRExercisingViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var timedView: MRTimedView!
    
    /// The controller's state
    private enum State {
        /// 4..3..2... go!
        case CountingDown
        /// started exercising at the given ``start``
        /// - parameter start: the exercise start for future labelling
        case Exercising(start: NSDate)
        /// done exercising: whatever label is going to be added, it happened between ``start`` for ``duration``
        /// - parameter start: the start of the label
        /// - parameter duration: the duration of the label
        case Done(start: NSDate, duration: NSTimeInterval)
    }

    private var state: State = State.CountingDown
    
    var session: MRManagedExerciseSession!
    
    override func viewDidLoad() {
        timedView.setColourScheme(MRColourSchemes.amber)
        timedView.elapsedResets = true
        tableView.registerNib(MRExerciseTableViewCell.nib, forCellReuseIdentifier: MRExerciseTableViewCell.cellReuseIdentifier)
    }
    
    override func viewDidAppear(animated: Bool) {
        tableView.allowsSelection = false
        timedView.start(5, onTimerElapsed: beginExercising)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionDidEstimate", name: MRNotifications.SessionDidEstimate.rawValue, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    ///
    /// This is a notification callback from the sessionDidEstimate. Do not call explicitly.
    ///
    func sessionDidEstimate() {
        tableView.reloadData()
    }
    
    private func beginExercising(tv: MRTimedView) {
        state = .Exercising(start: NSDate())
        session.beginExercising()
        timedView.setColourScheme(MRColourSchemes.red)
        timedView.setButtonTitle("done")
        tableView.reloadData()
        timedView.buttonTouched = stopExercising
    }
    
    private func stopExercising(tv: MRTimedView) {
        if case .Exercising(let start) = state {
            session.endExercise()
            timedView.setColourScheme(MRColourSchemes.green)
            let text = "✓"
            timedView.setButtonTitle(text)
            timedView.textTransform = { _ in return text }
            timedView.start(10, onTimerElapsed: ignoreLabel)
            tableView.allowsSelection = true
            tableView.reloadData()
            state = .Done(start: start, duration: NSDate().timeIntervalSinceDate(start))
        }
    }
    
    private func ignoreLabel(tv: MRTimedView) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    private func addLabel(e: MKIncompleteExercise) {
        if case .Done(let start, let duration) = state {
            session.addLabel(e, start: start, duration: duration, inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
            MRAppDelegate.sharedDelegate().saveContext()
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        switch state {
        case .CountingDown: return 0
        case .Exercising(_): return 1
        case .Done(_): return 3
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return session.exercises.count
        case 1: return 1
        case 2: return 1
        default: fatalError("Match error")
        }
    }
    
    func tableView(tableView: UITableView, accessoryTypeForRowWithIndexPath indexPath: NSIndexPath) -> UITableViewCellAccessoryType {
        if tableView.allowsSelection {
            return UITableViewCellAccessoryType.DisclosureIndicator
        } else {
            return UITableViewCellAccessoryType.None
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return MRExerciseTableViewCell.height
        case 1: return 40
        case 2: return 40
        default: fatalError("Match error")
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier(MRExerciseTableViewCell.cellReuseIdentifier, forIndexPath: indexPath) as! MRExerciseTableViewCell
            let plannedExercise = session.exercises[indexPath.row]
            cell.setExercise(plannedExercise, lastExercise: nil)
            return cell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("other", forIndexPath: indexPath) 
            cell.textLabel?.text = "Something else"
            return cell
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("other", forIndexPath: indexPath)
            cell.textLabel?.text = "Nothing"
            return cell
        default: fatalError("Match error")
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? MRExerciseTableViewCell,
           let e = cell.exercise {
           addLabel(e)
        }

    }
    
}
