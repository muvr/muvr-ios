import Foundation
import Charts

enum MRExerciseSessionPlanTableViewCellState {
    case Completed
    case Todo
}

///
/// Cell that displays exercise plan item
///
class MRExerciseSessionPlanResistanceExerciseTableViewCell : UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    
    func setResistanceExercise(exercise: MRResistanceExercise, state: MRExerciseSessionPlanTableViewCellState) -> Void {
        titleLabel.text = "Intensity"
        descriptionLabel.text = exercise.localisedTitle
        if state == .Completed { titleLabel.textColor = UIColor.greenColor() }
    }
    
}

///
/// Controls a view that displays the log of the current session
///
class MRExerciseSessionPlanViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    static let storyboardId: String = "MRExerciseSessionPlanViewController"
    @IBOutlet var tableView: UITableView!
    
    private struct Consts {
        static let Progress = 0
        static let Deviations = 1
    }
    
    private var plan: MRExercisePlan?
    
    func setExercisePlan(plan: MRExercisePlan) {
        self.plan = plan
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Consts.Progress: return plan!.todo.count + plan!.completed.count
        case Consts.Deviations: return plan!.deviations.count
        default: fatalError("Match error")
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Consts.Progress: return "Progress".localized()
        case Consts.Deviations: return "Deviations".localized()
        default: fatalError("Match error")
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case Consts.Progress: return 30
        case Consts.Deviations: return 30
        default: fatalError("Match error")
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (Consts.Progress, let x):
            let items = plan!.todo.map { ($0 as! MRExercisePlanItem, MRExerciseSessionPlanTableViewCellState.Todo) } +
                        plan!.completed.map { ($0 as! MRExercisePlanItem, MRExerciseSessionPlanTableViewCellState.Completed) }
            let (item, state) = items[x]
            if let resistanceExercise = item.resistanceExercise {
                let cell = tableView.dequeueReusableCellWithIdentifier("resistanceExercise") as! MRExerciseSessionPlanResistanceExerciseTableViewCell
                cell.setResistanceExercise(resistanceExercise, state: state)
                return cell
            }
            if let rest = item.rest {
                let cell = tableView.dequeueReusableCellWithIdentifier("rest") as! UITableViewCell
                return cell
            }
            
            fatalError("Bad item type")
        case (Consts.Deviations, let x):
            let cell = tableView.dequeueReusableCellWithIdentifier("deviation") as! UITableViewCell
            let item = plan!.deviations[x] as! MRExercisePlanDeviation
            cell.detailTextLabel!.text = item.description
            return cell
        default: fatalError("Match error")
        }
    }
    
}
