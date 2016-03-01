import UIKit
import MuvrKit
import JTCalendar

class MRStartWorkoutViewController: UIViewController, JTCalendarDelegate {

    @IBOutlet weak var calendarView: JTHorizontalCalendarView!
    @IBOutlet weak var startButton: MRWorkoutButton!
    @IBOutlet weak var scrollView: UIScrollView!
    private let calendar = JTCalendarManager()
    
    private var upcomingSessions: [MRSessionType] = []
    
    override func viewDidLoad() {
        let today = NSDate()
        calendar.settings.weekModeEnabled = true
        calendar.contentView = calendarView
        calendar.delegate = self
        calendar.setDate(today)
        calendar.reload()
    }
    
    override func viewWillAppear(animated: Bool) {
        upcomingSessions = MRAppDelegate.sharedDelegate().sessions
        displayWorkouts()
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
        if let session = upcomingSessions.first {
            startButton.session = session
        }
        
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        
        let buttonWidth = scrollView.frame.width / 3
        scrollView.contentSize = CGSizeMake(buttonWidth * CGFloat(upcomingSessions.count), scrollView.frame.height)
        let buttonColor = UIColor(colorLiteralRed: 0, green: 164 / 255, blue: 118 / 255, alpha: 1.0)
        
        if upcomingSessions.count > 1 {
            for session in upcomingSessions[1..<upcomingSessions.count] {
                let button = MRWorkoutButton(type: UIButtonType.System)
                button.color = buttonColor
                button.session = session
                button.setTitleColor(buttonColor, forState: .Normal)
                button.addTarget(self, action: #selector(MRStartWorkoutViewController.startWorkout(_:)), forControlEvents: [.TouchUpInside])
                scrollView.addSubview(button)
            }
        }
        
        // add "Start another workout" button
        let button = MRWorkoutButton(type: UIButtonType.System)
        button.color = .orangeColor()
        button.backgroundColor = .orangeColor()
        button.setTitleColor(.whiteColor(), forState: .Normal)
        button.setTitle("Start another workout", forState: .Normal)
        button.addTarget(self, action: #selector(MRStartWorkoutViewController.selectAnotherWorkout), forControlEvents: [.TouchUpInside])
        scrollView.addSubview(button)
        
    }
    
    func selectAnotherWorkout() {
        if let controller = storyboard?.instantiateViewControllerWithIdentifier("adhoc") {
            showViewController(controller, sender: self)
        }
    }
    
    @IBAction func startWorkout(sender: MRWorkoutButton) {
        if let session = sender.session {
            try! MRAppDelegate.sharedDelegate().startSession(session)
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
                dayView.circleView.backgroundColor = UIColor.grayColor()
                dayView.dotView.backgroundColor = UIColor.whiteColor()
                dayView.textLabel.textColor = UIColor.whiteColor()
            } else {
                dayView.circleView.hidden = true
                dayView.dotView.backgroundColor = UIView.appearance().tintColor
                dayView.textLabel.textColor = UIColor.blackColor()
            }
            
            
            dayView.dotView.hidden = !hasEvent(dayView.date)
        }
    }
    
}