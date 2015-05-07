import Foundation
import JTCalendar

class MRHomeViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, JTCalendarDataSource {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var calendarContentView: JTCalendarContentView!
    
    private let calendar = JTCalendar()
    private var resistanceExerciseSessions: [MRResistanceExerciseSession] = []
    private var resistanceExerciseSets: [MRResistanceExerciseSessionDetail] = []
    
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
        case Consts.Sessions: return resistanceExerciseSets.count
        default: fatalError("Match error")
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (Consts.Sessions, let x):
            let ((_, session), sets) = resistanceExerciseSets[x]
            let cell = tableView.dequeueReusableCellWithIdentifier("session") as! MRResistanceExerciseSetTableViewCell
            cell.title.text = ", ".join(session.properties.muscleGroupIds)
            return cell
        default:
            fatalError(":(")
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Consts.Sessions: return "Sessions".localized()
        default: fatalError("Match error")
        }
    }
    
    // MARK: JTCalendarDataSource
    
    func calendarHaveEvent(calendar: JTCalendar!, date: NSDate!) -> Bool {
        return resistanceExerciseSessions.find { elem in elem.startDate.dateOnly == date } != nil
    }
    
    func calendarDidDateSelected(calendar: JTCalendar!, date: NSDate!) {
        resistanceExerciseSets = MRApplicationState.loggedInState!.getResistanceExerciseSessionDetails(on: date)
        tableView.reloadData()
    }

}
