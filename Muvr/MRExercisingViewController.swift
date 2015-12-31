import UIKit

class MRExercisingViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var timedView: MRTimedView!

    var session: MRManagedExerciseSession!
    
    override func viewDidLoad() {
        timedView.setColourScheme(MRColourSchemes.amber)
        timedView.elapsedResets = true
        tableView.registerNib(MRExerciseTableViewCell.nib, forCellReuseIdentifier: MRExerciseTableViewCell.cellReuseIdentifier)
    }
    
    override func viewDidAppear(animated: Bool) {
        tableView.allowsSelection = false
        timedView.start(5, onTimerElapsed: beginExercising)
    }
    
    private func beginExercising(tv: MRTimedView) {
        timedView.setColourScheme(MRColourSchemes.red)
        timedView.setButtonTitle("stop")
        timedView.buttonTouched = stopExercising
    }
    
    private func stopExercising(tv: MRTimedView) {
        timedView.setColourScheme(MRColourSchemes.green)
        timedView.setButtonTitle("✓")
        tableView.allowsSelection = true
        tableView.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return session.suggestedExercises.count
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
        case 1: return 22
        case 2: return 22
        default: fatalError("Match error")
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier(MRExerciseTableViewCell.cellReuseIdentifier, forIndexPath: indexPath) as! MRExerciseTableViewCell
            let plannedExercise = session.suggestedExercises[indexPath.row]
            cell.setPlannedExecise(plannedExercise, lastPlannedExercise: nil)
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
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? MRExerciseTableViewCell {
            if let pe = cell.plannedExercise {
                session.addExercise(pe)
            }
        }

        // TODO: perform labelling
        navigationController?.popViewControllerAnimated(true)
    }
    
}
