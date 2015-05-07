import Foundation
import JTCalendar

class MRHomeViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, JTCalendarDataSource {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var calendarContentView: JTCalendarContentView!
    
    private let calendar = JTCalendar()
    private var resistanceExerciseSessions: [MRResistanceExerciseSession] = []
    private var resistanceExerciseSessionDetails: [MRResistanceExerciseSessionDetail] = []
    
    private struct Consts {
        static let Sessions = 0
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
        calendarContentView.reloadData()
        calendar.currentDate = NSDate()
        calendar.currentDateSelected = NSDate()
        calendarDidDateSelected(self.calendar, date: NSDate())
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Consts.Sessions: return resistanceExerciseSessionDetails.count
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
        default: fatalError("Match error")
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            switch (indexPath.section, indexPath.row) {
            case (Consts.Sessions, let x):
                let ((id, _), _) = resistanceExerciseSessionDetails[x]
                MRApplicationState.loggedInState!.deleteSession(id)
                resistanceExerciseSessionDetails = resistanceExerciseSessionDetails.filter { $0.0.0 != id }
                tableView.reloadData()
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
        tableView.reloadData()
    }

}
