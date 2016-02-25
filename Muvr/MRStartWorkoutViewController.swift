import UIKit
import MuvrKit
import JTCalendar

class MRStartWorkoutViewController: UIViewController, JTCalendarDelegate {

    @IBOutlet weak var calendarView: JTHorizontalCalendarView!
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    private let calendar = JTCalendarManager()
    
    private var exerciseType: MKExerciseType? = .ResistanceTargeted(muscleGroups: [.Arms, .Shoulders, .Chest])
    
    override func viewDidLayoutSubviews() {
        changeButton.titleLabel?.textAlignment = .Center
        changeButton.layer.cornerRadius = changeButton.frame.width / 2
        
        startButton.titleLabel?.textAlignment = .Center
        startButton.layer.cornerRadius =  startButton.frame.height / 2
    }
    
    override func viewDidLoad() {
        let today = NSDate()
        calendar.menuView = JTCalendarMenuView()
        calendar.contentView = calendarView
        calendar.settings.weekModeEnabled = true
        calendar.delegate = self
        
        calendar.setDate(today)
        calendar.reload()
        
        displayDefaultWorkout()
    }
    
    private func displayDefaultWorkout() {
        if let exerciseType = exerciseType {
            switch exerciseType {
            case .ResistanceTargeted(let muscles): startButton.setTitle("Start \(muscles.map { $0.id }.joinWithSeparator(", ")) workout", forState: .Normal)
            case .IndoorsCardio: startButton.setTitle("Start cardio workout", forState: .Normal)
            case .ResistanceWholeBody: startButton.setTitle("Start whole-body workout", forState: .Normal)
            }
        }
    }
    
    @IBAction func startWorkout(sender: UIButton) {
        if let exerciseType = exerciseType {
            try! MRAppDelegate.sharedDelegate().startSession(forExerciseType: exerciseType)
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