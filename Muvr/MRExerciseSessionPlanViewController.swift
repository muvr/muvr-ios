import Foundation

///
/// Controls a view that displays the log of the current session
///
class MRExerciseSessionPlanViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    static let storyboardId: String = "MRExerciseSessionPlanViewController"
    @IBOutlet var tableView: UITableView!
    
    private struct Consts {
        static let Todo = 0
        static let Completed = 1
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
        case Consts.Todo: return plan!.todo().count
        case Consts.Completed: return plan!.completed().count
        default: fatalError("Match error")
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Consts.Todo: return "Todo".localized()
        case Consts.Completed: return "Completed".localized()
        default: fatalError("Match error")
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (Consts.Todo, let x):
            let cell = tableView.dequeueReusableCellWithIdentifier("todo") as! UITableViewCell
            let item = plan!.todo()[x] as! MRExercisePlanItem
            cell.textLabel!.text = item.description
            return cell
        case (Consts.Completed, let x):
            let cell = tableView.dequeueReusableCellWithIdentifier("completed") as! UITableViewCell
            let item = plan!.completed()[x] as! MRExercisePlanItem
            cell.textLabel!.text = item.description
            return cell
        default: fatalError("Match error")
        }
    }
    
}