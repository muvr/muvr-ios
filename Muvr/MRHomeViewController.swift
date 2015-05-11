import Foundation
import JTCalendar

class MRHomeViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, JTCalendarDataSource {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var calendarContentView: JTCalendarContentView!
    
    private let calendar = JTCalendar()
    private var resistanceExerciseSessions: [MRResistanceExerciseSession] = []
    private var resistanceExerciseSessionDetails: [MRResistanceExerciseSessionDetail] = []
    private var resistanceExercisePlans: [MRResistanceExercisePlan] = []
    
    private struct Consts {
        static let Sessions = 0
        static let ResistancePlans = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        calendar.calendarAppearance.isWeekMode = true
        calendar.menuMonthsView = JTCalendarMenuView()
        calendar.contentView = calendarContentView
        
        calendar.dataSource = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        resistanceExerciseSessions = MRApplicationState.loggedInState!.getResistanceExerciseSessions()
        calendar.reloadData()
        calendar.currentDate = NSDate()
        calendar.currentDateSelected = NSDate()
        calendarDidDateSelected(calendar, date: NSDate())
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Consts.Sessions: return resistanceExerciseSessionDetails.count
        case Consts.ResistancePlans: return resistanceExercisePlans.count
        default: fatalError("Match error")
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (Consts.Sessions, let x):
            let ((_, session), sets) = resistanceExerciseSessionDetails[x]
            let cell = tableView.dequeueReusableCellWithIdentifier("session") as! MRResistanceExerciseSetTableViewCell
            cell.setSession(session, andSets: sets)
            return cell
        case (Consts.ResistancePlans, let x):
            let plan = resistanceExercisePlans[x]
            let cell = tableView.dequeueReusableCellWithIdentifier("resistancePlan") as! UITableViewCell
            cell.textLabel!.text = MRApplicationState.joinMuscleGroups(plan.muscleGroupIds)
            cell.detailTextLabel!.text = plan.title
            return cell
        default:
            fatalError(":(")
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case Consts.Sessions: return 100
        default: return 44
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Consts.Sessions: return "Sessions".localized()
        case Consts.ResistancePlans: return "Resistance plans".localized()
        default: fatalError("Match error")
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (Consts.Sessions, let x):
            // noop
            return
        case (Consts.ResistancePlans, let x):
            performSegueWithIdentifier("startPlan", sender: x)
        default: fatalError("Match error")
        }
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        switch indexPath.section {
        case Consts.Sessions: return UITableViewCellEditingStyle.Delete
        default: return UITableViewCellEditingStyle.None
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            switch (indexPath.section, indexPath.row) {
            case (Consts.Sessions, let x):
                let ((id, _), _) = resistanceExerciseSessionDetails[x]
                MRApplicationState.loggedInState!.deleteSession(id)
                resistanceExerciseSessions = MRApplicationState.loggedInState!.getResistanceExerciseSessions()
                calendar.reloadData()
                calendarDidDateSelected(calendar, date: calendar.currentDateSelected)
            default:
                // noop
                return
            }
        }
    }
    
    // MARK: JTCalendarDataSource
    
    func calendarHaveEvent(calendar: JTCalendar!, date: NSDate!) -> Bool {
        return resistanceExerciseSessions.find { elem in elem.startDate.dateOnly == date } != nil
    }
    
    func calendarDidDateSelected(calendar: JTCalendar!, date: NSDate!) {
        resistanceExerciseSessionDetails = MRApplicationState.loggedInState!.getResistanceExerciseSessionDetails(on: date)
        resistanceExercisePlans = MRApplicationState.loggedInState!.getSimpleResistanceExercisePlansOn(on: date)
        tableView.reloadData()
    }
    
    // MARK: Transition to exercising
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let ctrl = segue.destinationViewController as? MRExerciseSessionViewController,
            let planIndex = sender as? Int {
                let plan = resistanceExercisePlans[planIndex]
                let properties = MRResistanceExerciseSessionProperties(intendedIntensity: plan.intendedIntensity, muscleGroupIds: plan.muscleGroupIds)
                ctrl.startSession(MRApplicationState.loggedInState!.startSession(properties),
                    withPlan: MRExercisePlan(resistanceExercises: plan.exercises, andDefaultDuration: 20000))
        }
    }

}
