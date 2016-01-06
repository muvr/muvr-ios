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
        case Done(start: NSDate, duration: NSTimeInterval, labelling: Bool)
        /// done exercising: user has selected a group in the list
        case ExerciseGroupSelected(start: NSDate, duration: NSTimeInterval, group: String)
        /// done exercising: user has selected his exercise in the list
        case ExerciseSelected(start: NSDate, duration: NSTimeInterval, exercise: MKIncompleteExercise)
    }

    private var state: State = State.CountingDown
    private var tableController: MRTableController? = nil
    var session: MRManagedExerciseSession!
    
    override func viewDidLoad() {
        timedView.setColourScheme(MRColourSchemes.amber)
        timedView.elapsedResets = false
        timedView.buttonTouchResets = false
        tableView.registerNib(MRExerciseTableViewCell.nib, forCellReuseIdentifier: MRExerciseTableViewCell.cellReuseIdentifier)
    }
    
    override func viewDidAppear(animated: Bool) {
        if case .CountingDown = state {
            tableView.allowsSelection = false
            timedView.setConstantTitle("ready")
            timedView.start(5, onTimerElapsed: beginExercising)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionDidEstimate", name: MRNotifications.SessionDidEstimate.rawValue, object: nil)
        }
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
        timedView.setColourScheme(MRColourSchemes.red)
        timedView.countingStyle = .Elapsed
        timedView.setConstantTitle("done")
        timedView.buttonTouched = stopExercising
        timedView.start(60)
        
        changeState(.Exercising(start: NSDate()))
    }
    
    private func stopExercising(tv: MRTimedView) {
        if case .Exercising(let start) = state {
            session.endExercise()
            
            timedView.setColourScheme(MRColourSchemes.green)
            timedView.setConstantTitle("✓")
            timedView.countingStyle = .Remaining
            timedView.start(15, onTimerElapsed: ignoreLabel)
            
            changeState(.Done(start: start, duration: NSDate().timeIntervalSinceDate(start), labelling: false))
        }
    }
    
    private func ignoreLabel(tv: MRTimedView) {
        if case .Done(_, _, let selecting) = state where !selecting {
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func addLabel(e: MKIncompleteExercise) {
        if case .ExerciseSelected(let start, let duration, _) = state {
            session.addLabel(e, start: start, duration: duration, inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
            MRAppDelegate.sharedDelegate().saveContext()
            changeState(.CountingDown)
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    private func changeState(newState: State) {
        state = newState
        switch (newState) {
        case .CountingDown:
            tableView.allowsSelection = false
            break
        case .Exercising(_):
            session.beginExercising()
            tableController = InExerciseTableController(controller: self)
            tableView.reloadData()
            break
        case .Done(let start, let duration, _):
            tableController = DoneTableController(controller: self, start: start, duration: duration)
            tableView.allowsSelection = true
            tableView.reloadData()
            break
        case .ExerciseGroupSelected(let start, let duration, let group):
            tableController = GroupSelectedTableController(controller: self, start: start, duration: duration, group: group)
            tableView.reloadData()
            break
        case .ExerciseSelected(_):
            performSegueWithIdentifier("labelling", sender: self)
            break
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return tableController?.numberOfSectionsInTableView?(tableView) ?? 0
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableController?.tableView(tableView, numberOfRowsInSection: section) ?? 0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return tableController?.tableView?(tableView, heightForRowAtIndexPath: indexPath) ?? 40
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return tableController!.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableController?.tableView?(tableView, didSelectRowAtIndexPath: indexPath)
    }
    
    private func textCell(text: String, forIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("other", forIndexPath: indexPath)
        cell.textLabel?.text = text
        cell.detailTextLabel?.text = ""
        cell.accessoryType = tableView.allowsSelection ? .DisclosureIndicator : .None
        return cell
    }
    
    private func exerciseCell(exercise: MKIncompleteExercise, forIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MRExerciseTableViewCell.cellReuseIdentifier, forIndexPath: indexPath) as! MRExerciseTableViewCell
        cell.setExercise(exercise, lastExercise: nil)
        cell.accessoryType = tableView.allowsSelection ? .DisclosureIndicator : .None
        return cell
    }
    
    
    ///
    /// Table controller used when in .Done state
    ///
    class DoneTableController: NSObject, MRTableController {
    
        let controller: MRExercisingViewController
        let start: NSDate
        let duration: NSTimeInterval
        
        init(controller: MRExercisingViewController, start: NSDate, duration: NSTimeInterval) {
            self.controller = controller
            self.start = start
            self.duration = duration
        }
        
        func numberOfSectionsInTableView(tableView: UITableView) -> Int {
            return 3
        }
        
        func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            switch section {
            case 0: return controller.session.exercises.count
            case 1: return controller.session.exerciseGroups.count
            case 2: return 1
            default: fatalError("Match error")
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
            case 0: return controller.exerciseCell(controller.session.exercises[indexPath.row], forIndexPath: indexPath)
            case 1: return controller.textCell(controller.session.exerciseGroups[indexPath.row], forIndexPath: indexPath)
            case 2: return controller.textCell("Nothing", forIndexPath: indexPath)
            default: fatalError("Match error")
            }
        }
        
        func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? MRExerciseTableViewCell,
                let e = cell.exercise {
                    controller.changeState(.ExerciseSelected(start: start, duration: duration, exercise: e))
            }
            if indexPath.section == 1 {
                let group = controller.session.exerciseGroups[indexPath.row]
                controller.changeState(.ExerciseGroupSelected(start: start, duration: duration, group: group))
                tableView.reloadData()
            }
            if indexPath.section == 2 { controller.ignoreLabel(controller.timedView) }
        }
    }
    
    ///
    /// Table controller used when in .ExerciseGroupSelected state
    ///
    class GroupSelectedTableController: NSObject, MRTableController {
        
        let controller: MRExercisingViewController
        let group: String
        let start: NSDate
        let duration: NSTimeInterval
        
        init(controller: MRExercisingViewController, start: NSDate, duration: NSTimeInterval, group: String) {
            self.controller = controller
            self.start = start
            self.duration = duration
            self.group = group
        }
        
        func numberOfSectionsInTableView(tableView: UITableView) -> Int {
            return 2
        }
        
        func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            switch section {
            case 0: return controller.session.exercisesInGroup(group).count
            case 1: return 1
            default: fatalError("Match error")
            }
        }
        
        func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            switch indexPath.section {
            case 0: return MRExerciseTableViewCell.height
            case 1: return 40
            default: fatalError("Match error")
            }
        }
        
        func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            switch indexPath.section {
            case 0: return controller.exerciseCell(controller.session.exercisesInGroup(group)[indexPath.row], forIndexPath: indexPath)
            case 1: return controller.textCell("Something else", forIndexPath: indexPath)
            default: fatalError("Match error")
            }
        }
        
        func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? MRExerciseTableViewCell,
                let e = cell.exercise {
                    controller.changeState(.ExerciseSelected(start: start, duration: duration, exercise: e))
            }
            if indexPath.section == 1 {
                controller.changeState(.Done(start: start, duration: duration, labelling: true))
            }
        }
    }
    
    ///
    /// Table controller used when in .Exercising state
    ///
    class InExerciseTableController: NSObject, MRTableController {
        
        let controller: MRExercisingViewController
        
        init(controller: MRExercisingViewController) {
            self.controller = controller
        }
        
        func numberOfSectionsInTableView(tableView: UITableView) -> Int {
            return 1
        }
        
        func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return controller.session.exercises.count
        }
        
        func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            return MRExerciseTableViewCell.height
        }
        
        func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            return controller.exerciseCell(controller.session.exercises[indexPath.row], forIndexPath: indexPath)
        }
        
        func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            
        }
        
    }
}

protocol MRTableController: UITableViewDataSource, UITableViewDelegate { }
