import Foundation
import JTCalendar

class MRHomeViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, JTCalendarDataSource {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var calendarContentView: JTCalendarContentView!
    
    private let calendar = JTCalendar()
    private var resistanceExerciseSessions: [MRResistanceExerciseSession] = []
    
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
        return 3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        fatalError(":(")
    }
    
    // MARK: JTCalendarDataSource
    
    func calendarHaveEvent(calendar: JTCalendar!, date: NSDate!) -> Bool {
        return resistanceExerciseSessions.find { elem in elem.startDate.dateOnly == date } != nil
    }
    
    func calendarDidDateSelected(calendar: JTCalendar!, date: NSDate!) {
        NSLog("...")
    }

}
