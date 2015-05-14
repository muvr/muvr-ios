import Foundation
import Charts

///
/// Cell that displays exercise plan item
///
class MRExerciseSessionPlanResistanceExerciseTableViewCell : UITableViewCell {
    
    func setResistanceExercise(exercise: MRResistanceExercise) -> Void {
        textLabel!.text = "Intensity"
        detailTextLabel!.text = exercise.localisedTitle
    }
    
}

class MRExerciseSessionPlanRestTableViewCell : UITableViewCell {
    
    func setRest(rest: MRRest) -> Void {
        detailTextLabel!.text = "\(rest.minimumDuration) remaining" //"%d remaining".localized()
    }
}

extension UITableViewCell {
    
    func markCompleted() -> Void {
        textLabel!.textColor = UIColor.greenColor()
    }

}

///
/// Controls a view that displays the log of the current session
///
class MRExerciseSessionPlanViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, MRExerciseSessionSubviewDelegate {
    static let storyboardId: String = "MRExerciseSessionPlanViewController"
    @IBOutlet var tableView: UITableView?
    
    private var completed: [MRExercisePlanItem] = []
    private var todo: [MRExercisePlanItem] = []
    private var current: MRExercisePlanItem? = nil
    private var deviations: [MRExercisePlanDeviation] = []
    
    private struct Consts {
        static let Completed = 0
        static let Current = 1
        static let Todo = 2
        static let Deviations = 3
    }
    
    private var plan: MRExercisePlan?
    
    func setExercisePlan(plan: MRExercisePlan) {
        self.plan = plan
        sessionUpdated()
    }
    
    func sessionUpdated() {
        todo = plan!.todo as! [MRExercisePlanItem]
        completed = plan!.completed as! [MRExercisePlanItem]
        current = plan!.current
        deviations = plan!.deviations as! [MRExercisePlanDeviation]
        
        tableView?.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Consts.Completed: return completed.count
        case Consts.Current: return current != nil ? 1 : 0
        case Consts.Todo: return todo.count
        case Consts.Deviations: return deviations.count
        default: fatalError("Match error")
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Consts.Todo: return "Coming up".localized()
        case Consts.Current: return "Current".localized()
        case Consts.Completed: return "Completed".localized()
        case Consts.Deviations: return "Deviations".localized()
        default: fatalError("Match error")
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 38
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        func dequeueExerciseCell(item: MRExercisePlanItem, completed: Bool) -> UITableViewCell {
            if let resistanceExercise = item.resistanceExercise {
                let cell = tableView.dequeueReusableCellWithIdentifier("resistanceExercise") as! MRExerciseSessionPlanResistanceExerciseTableViewCell
                cell.setResistanceExercise(resistanceExercise)
                if completed { cell.markCompleted() }
                return cell
            }
            if let rest = item.rest {
                let cell = tableView.dequeueReusableCellWithIdentifier("rest") as! MRExerciseSessionPlanRestTableViewCell
                cell.setRest(item.rest)
                if completed { cell.markCompleted() }
                return cell
            }
            
            fatalError("Bad item type")
        }
        
        switch (indexPath.section, indexPath.row) {
        case (Consts.Current, 0):
            return dequeueExerciseCell(current!, false)
        case (Consts.Completed, let x):
            return dequeueExerciseCell(completed[completed.count - 1 - x], true)
        case (Consts.Todo, let x):
            return dequeueExerciseCell(todo[x], false)
        case (Consts.Deviations, let x):
            let cell = tableView.dequeueReusableCellWithIdentifier("deviation") as! UITableViewCell
            let item = plan!.deviations[x] as! MRExercisePlanDeviation
            cell.detailTextLabel!.text = item.description
            return cell
        default: fatalError("Match error")
        }
    }
    
}
