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
        /// done exercising: user has selected a group in the list
        case ExerciseGroupSelected(start: NSDate, duration: NSTimeInterval, group: String)
        /// done exercising: user has selected his exercise in the list
        case ExerciseSelected(start: NSDate, duration: NSTimeInterval, exercise: MKIncompleteExercise)
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
        timedView.setConstantTitle("ready")
        timedView.start(5, onTimerElapsed: beginExercising)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionDidEstimate", name: MRNotifications.SessionDidEstimate.rawValue, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let c = segue.destinationViewController as? MRLabellingViewController,
           case .ExerciseSelected(let start, let duration, let exercise) = state {
            c.session = session
            c.exercise = exercise
            c.start = start
            c.duration = duration
        }
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
        timedView.countingStyle = .Elapsed
        timedView.setConstantTitle("done")
        timedView.buttonTouched = stopExercising
        timedView.start(60)

        tableView.reloadData()
    }
    
    private func stopExercising(tv: MRTimedView) {
        if case .Exercising(let start) = state {
            session.endExercise()
            
            timedView.setColourScheme(MRColourSchemes.green)
            timedView.setConstantTitle("✓")
            timedView.countingStyle = .Remaining
            timedView.start(15, onTimerElapsed: ignoreLabel)
            
            state = .Done(start: start, duration: NSDate().timeIntervalSinceDate(start))
            
            tableView.allowsSelection = true
            tableView.reloadData()
        }
    }
    
    private func ignoreLabel(tv: MRTimedView) {
        if case .Done(_) = state {
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func addLabel(e: MKIncompleteExercise) {
        if case .ExerciseSelected(let start, let duration, _) = state {
            session.addLabel(e, start: start, duration: duration, inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
            MRAppDelegate.sharedDelegate().saveContext()
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        switch state {
        case .CountingDown: return 0
        case .Exercising(_): return 1
        case .Done(_): return 4
        case .ExerciseGroupSelected(_): return 2
        case .ExerciseSelected(_): return 0
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch state {
        case .CountingDown: return 0
        case .Exercising(_): return session.exercises.count
        case .Done(_):
            switch section {
            case 0: return session.exercises.count
            case 1: return session.exerciseGroups.count
            case 2: return 1
            case 3: return 1
            default: fatalError("Match error")
            }
        case .ExerciseGroupSelected(_,_, let group):
            switch section {
            case 0: return session.exercisesInGroup(group).count
            case 1: return 1
            default: fatalError("Match error")
            }
        case .ExerciseSelected(_): return 0
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
        case 3: return 40
        default: fatalError("Match error")
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if case .ExerciseGroupSelected(_, _, let group) = state {
                let cell = tableView.dequeueReusableCellWithIdentifier(MRExerciseTableViewCell.cellReuseIdentifier, forIndexPath: indexPath) as! MRExerciseTableViewCell
                let plannedExercise = session.exercisesInGroup(group)[indexPath.row]
                cell.setExercise(plannedExercise, lastExercise: nil)
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier(MRExerciseTableViewCell.cellReuseIdentifier, forIndexPath: indexPath) as! MRExerciseTableViewCell
                let plannedExercise = session.exercises[indexPath.row]
                cell.setExercise(plannedExercise, lastExercise: nil)
                return cell
            }
        case 1:
            if case .ExerciseGroupSelected(_) = state {
                let cell = tableView.dequeueReusableCellWithIdentifier("other", forIndexPath: indexPath)
                cell.textLabel?.text = "Something else"
                cell.detailTextLabel?.text = ""
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("other", forIndexPath: indexPath)
                cell.textLabel?.text = session.exerciseGroups[indexPath.row]
                cell.detailTextLabel?.text = ""
                return cell
            }
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("other", forIndexPath: indexPath) 
            cell.textLabel?.text = "Something else"
            cell.detailTextLabel?.text = ""
            return cell
        case 3:
            let cell = tableView.dequeueReusableCellWithIdentifier("other", forIndexPath: indexPath)
            cell.textLabel?.text = "Nothing"
            cell.detailTextLabel?.text = ""
            return cell
        default: fatalError("Match error")
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? MRExerciseTableViewCell,
           let e = cell.exercise {
            if case .Done(let start, let duration) = state {
                state = .ExerciseSelected(start: start, duration: duration, exercise: e)
            }
            if case .ExerciseGroupSelected(let start, let duration, _) = state {
                state = .ExerciseSelected(start: start, duration: duration, exercise: e)
            }
            performSegueWithIdentifier("labelling", sender: self)
            return
        }
        if case .Done(let start, let duration) = state where indexPath.section == 1 {
            let group = session.exerciseGroups[indexPath.row]
            state = .ExerciseGroupSelected(start: start, duration: duration, group: group)
            tableView.reloadData()
            return
        }
        if case .ExerciseGroupSelected(let start, let duration, _) = state where indexPath.section == 1 {
            state = .Done(start: start, duration: duration)
            tableView.reloadData()
            return
        }
        if indexPath.section == 3 { ignoreLabel(timedView) }
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if case .Done(_, _) = state {
            timedView.stop()
        }
    }
}
