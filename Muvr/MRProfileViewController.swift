import UIKit
import MuvrKit
import JTCalendar

class MRProfileViewController : UIViewController, UITableViewDataSource, JTCalendarDelegate {
    
    @IBOutlet weak var calendarView: JTHorizontalCalendarView!
    @IBOutlet weak var sessionTable: UITableView!
    
    private let calendar = JTCalendarManager()
    private var selectedDate: Date = Date()
    private var sessionsOnDate: [MRManagedExerciseSession] = []
    
    
    
    @IBAction private func initialSetup() {
        MRAppDelegate.sharedDelegate().initialSetup()
    }
    
    override func viewDidLoad() {
        setTitleImage(named: "muvr_logo_white")
        
        let today = Date()
        calendar.settings.weekModeEnabled = true
        calendar.contentView = calendarView
        calendar.delegate = self
        calendar.setDate(today)
        
        sessionTable.dataSource = self
        selectedDate = today
        sessionsOnDate = MRAppDelegate.sharedDelegate().sessionsOnDate(today)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        sessionsOnDate = MRAppDelegate.sharedDelegate().sessionsOnDate(selectedDate)
        calendar.reload()
        sessionTable.reloadData()
    }
    
    // MARK: JTCalendarDelegate
    
    func calendar(_ calendar: JTCalendarManager!, prepareDayView dv: UIView!) {
        JTCalendarHelper.calendar(calendar, prepareDayView: dv, on: calendar.date()) { date in
            let dayView = dv as! JTCalendarDayView
            return MRAppDelegate.sharedDelegate().hasSessionsOnDate(dayView.date)
        }
    }
    
    func calendar(_ calendar: JTCalendarManager!, didTouchDayView dv: UIView!) {
        let dayView = dv as! JTCalendarDayView
        calendar.setDate(dayView.date)
        selectedDate = dayView.date
        sessionsOnDate = MRAppDelegate.sharedDelegate().sessionsOnDate(selectedDate)
        sessionTable.reloadData()
    }
    
    ///
    /// This implementation displays a page with date that falls before the end of this week. We compute
    /// that by working out the date at the end of this week and comparing it with the given ``date``.
    ///
    func calendar(_ calendar: JTCalendarManager!, canDisplayPageWithDate date: Date!) -> Bool {
        let today = Date()
        
        // today as the day of week, where 1 is the first day of week (e.g. Monday in UK, Sunday in US, etc.)
        let weekDay = Calendar.current().components(.weekday, from: today).weekday
        // the end of the week where ``today`` falls into
        let dateAtEndOfWeek = today.addDays(8 - weekDay)
        
        return date.compare(dateAtEndOfWeek) == .OrderedAscending
    }
    
    ///
    /// Change the font of the week day labels
    ///
    func calendarBuildWeekDayView(_ calendar: JTCalendarManager!) -> UIView! {
        let view = JTCalendarWeekDayView()
        for label in view.dayViews as! [UILabel] {
            label.font = UIFont.boldSystemFontOfSize(label.font.pointSize)
            label.textColor = MRColor.black
        }
        return view
    }
    
    // MARK: TableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, sessionsOnDate.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sessionCell", for: indexPath)
        if sessionsOnDate.isEmpty {
            if selectedDate.dateOnly == Date().dateOnly { cell.textLabel?.text = "No workout for today yet".localized() }
            else { cell.textLabel?.text = "No workout".localized() }
        } else {
            let session = sessionsOnDate[(indexPath as NSIndexPath).row]
            let format = DateFormatter()
            format.dateStyle = .noStyle
            format.timeStyle = .shortStyle
            cell.textLabel?.text = "\(format.string(from: session.start as Date)) \(session.name)"
        }
        return cell
    }

}

struct JTCalendarHelper {
    typealias HasEvent = (Date) -> Bool
    private static let dateHelper: JTDateHelper = JTDateHelper()
    
    static func calendar(_ calendar: JTCalendarManager!, prepareDayView dv: UIView!,
                         on selectedDate: Date?, hasEvent: HasEvent) {
        
        if let dayView = dv as? JTCalendarDayView {
            // Today
            if JTCalendarHelper.dateHelper.date(selectedDate, isTheSameDayThan: dayView.date) ?? false {
                dayView.circleView.hidden = false
                dayView.circleView.backgroundColor = UIView.appearance().tintColor
                dayView.dotView.backgroundColor = UIColor.whiteColor()
                dayView.textLabel.textColor = UIColor.whiteColor()
            } else if JTCalendarHelper.dateHelper.date(Date(), isTheSameDayThan: dayView.date) {
                dayView.circleView.hidden = false
                dayView.circleView.backgroundColor = MRColor.gray
                dayView.dotView.backgroundColor = UIColor.whiteColor()
                dayView.textLabel.textColor = UIColor.whiteColor()
            } else {
                dayView.circleView.hidden = true
                dayView.dotView.backgroundColor = MRColor.orange
                dayView.textLabel.textColor = MRColor.black
            }
            
            
            dayView.dotView.hidden = !hasEvent(dayView.date)
        }
    }
    
}
