import UIKit
import MuvrKit
import JTCalendar

class MRStartWorkoutViewController: UIViewController, UITableViewDataSource, JTCalendarDelegate  {
    @IBOutlet weak var calendarView: JTHorizontalCalendarView!
    @IBOutlet weak var startButton: MRAlternativeWorkoutButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var sessionTable: UITableView!
    private var manualViewController: MRManualViewController!
    private let calendar = JTCalendarManager()
    private var selectedDate: NSDate = NSDate()
    private var sessionsOnDate: [MRManagedExerciseSession] = []
    
    private var upcomingSessionTypes: [MRSessionType] = []
    private var selectedSessionType: MRSessionType? = nil
    
    override func viewDidLoad() {
        manualViewController = storyboard?.instantiateViewControllerWithIdentifier("adhoc") as! MRManualViewController
        
        let today = NSDate()
        calendar.settings.weekModeEnabled = true
        calendar.contentView = calendarView
        calendar.delegate = self
        calendar.setDate(today)
        
        sessionTable.dataSource = self
        selectedDate = today
        sessionsOnDate = MRAppDelegate.sharedDelegate().sessionsOnDate(today)
        
        setTitleImage(named: "muvr_logo_white")
    }
    
    override func viewWillAppear(animated: Bool) {
        upcomingSessionTypes = MRAppDelegate.sharedDelegate().sessions
        sessionsOnDate = MRAppDelegate.sharedDelegate().sessionsOnDate(selectedDate)
        displayWorkouts()
        calendar.reload()
        sessionTable.reloadData()
    }
    
    ///
    /// Compute the buttons' frames after scrollView layout
    ///
    override func viewDidLayoutSubviews() {
        let buttonWidth = scrollView.frame.width / 3
        let buttonPadding: CGFloat = 5
        scrollView.contentSize = CGSizeMake(buttonWidth * CGFloat(scrollView.subviews.count), scrollView.frame.height)
        for (index, button) in scrollView.subviews.enumerate() {
            button.frame = CGRectMake(CGFloat(index) * buttonWidth + (buttonPadding / 2), buttonPadding, buttonWidth - buttonPadding, buttonWidth - buttonPadding)
        }
    }

    
    private func displayWorkouts() {
        if let sessionType = upcomingSessionTypes.first {
            selectedSessionType = sessionType
            startButton.setTitle("Start %@".localized(sessionType.name), forState: .Normal)
        }
        
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        
        let buttonWidth = scrollView.frame.width / 3
        scrollView.contentSize = CGSizeMake(buttonWidth * CGFloat(upcomingSessionTypes.count), scrollView.frame.height)
        
        if upcomingSessionTypes.count > 1 {
            for sessionType in upcomingSessionTypes {
                let button = MRAlternativeWorkoutButton(type: UIButtonType.System)
                button.color = MRColor.green
                button.sessionType = sessionType
                button.setTitleColor(MRColor.green, forState: .Normal)
                button.addTarget(self, action: #selector(MRStartWorkoutViewController.changeWorkout(_:)), forControlEvents: [.TouchUpInside])
                scrollView.addSubview(button)
            }
        }
        
        // add "Start another workout" button
        let button = MRAlternativeWorkoutButton(type: UIButtonType.System)
        button.color = MRColor.orange
        button.backgroundColor = MRColor.orange
        button.setTitleColor(.whiteColor(), forState: .Normal)
        button.setTitle("Start another workout".localized(), forState: .Normal)
        button.addTarget(self, action: #selector(MRStartWorkoutViewController.selectAnotherWorkout), forControlEvents: [.TouchUpInside])
        scrollView.addSubview(button)
        
    }
    
    @objc private func selectAnotherWorkout() {
        showViewController(manualViewController, sender: self)
    }
    
    @objc private func changeWorkout(sender: MRAlternativeWorkoutButton) {
        if let sessionType = sender.sessionType {
            selectedSessionType = sessionType
            startButton.setTitle("Start %@".localized(sessionType.name), forState: .Normal)
        }
    }
    
    @IBAction private func startWorkout(sender: MRAlternativeWorkoutButton) {
        if let sessionType = selectedSessionType {
            try! MRAppDelegate.sharedDelegate().startSession(sessionType)
        }
    }
    
    // MARK: JTCalendarDelegate
    
    func calendar(calendar: JTCalendarManager!, prepareDayView dv: UIView!) {
        JTCalendarHelper.calendar(calendar, prepareDayView: dv, on: calendar.date()) { date in
            let dayView = dv as! JTCalendarDayView
            return MRAppDelegate.sharedDelegate().hasSessionsOnDate(dayView.date)
        }
    }
    
    func calendar(calendar: JTCalendarManager!, didTouchDayView dv: UIView!) {
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
    func calendar(calendar: JTCalendarManager!, canDisplayPageWithDate date: NSDate!) -> Bool {
        let today = NSDate()
        
        // today as the day of week, where 1 is the first day of week (e.g. Monday in UK, Sunday in US, etc.)
        let weekDay = NSCalendar.currentCalendar().components(.Weekday, fromDate: today).weekday
        // the end of the week where ``today`` falls into
        let dateAtEndOfWeek = today.addDays(8 - weekDay)
        
        return date.compare(dateAtEndOfWeek) == .OrderedAscending
    }
    
    ///
    /// Change the font of the week day labels
    ///
    func calendarBuildWeekDayView(calendar: JTCalendarManager!) -> UIView! {
        let view = JTCalendarWeekDayView()
        for label in view.dayViews as! [UILabel] {
            label.font = UIFont.boldSystemFontOfSize(label.font.pointSize)
            label.textColor = MRColor.black
        }
        return view
    }
    
    // MARK: TableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, sessionsOnDate.count)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("sessionCell", forIndexPath: indexPath)
        if sessionsOnDate.isEmpty {
            if selectedDate.dateOnly == NSDate().dateOnly { cell.textLabel?.text = "No workout for today yet".localized() }
            else { cell.textLabel?.text = "No workout".localized() }
        } else {
            let session = sessionsOnDate[indexPath.row]
            let format = NSDateFormatter()
            format.dateStyle = .NoStyle
            format.timeStyle = .ShortStyle
            cell.textLabel?.text = "\(format.stringFromDate(session.start)) \(session.name)"
        }
        return cell
    }
    
}

struct JTCalendarHelper {
    typealias HasEvent = NSDate -> Bool
    private static let dateHelper: JTDateHelper = JTDateHelper()
    
    static func calendar(calendar: JTCalendarManager!, prepareDayView dv: UIView!,
                         on selectedDate: NSDate?, hasEvent: HasEvent) {
        
        if let dayView = dv as? JTCalendarDayView {
            // Today
            if JTCalendarHelper.dateHelper.date(selectedDate, isTheSameDayThan: dayView.date) ?? false {
                dayView.circleView.hidden = false
                dayView.circleView.backgroundColor = UIView.appearance().tintColor
                dayView.dotView.backgroundColor = UIColor.whiteColor()
                dayView.textLabel.textColor = UIColor.whiteColor()
            } else if JTCalendarHelper.dateHelper.date(NSDate(), isTheSameDayThan: dayView.date) {
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