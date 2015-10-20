import UIKit
import JTCalendar

class MRHomeViewController : UIViewController, JTCalendarDelegate {
    @IBOutlet var calendarContentView: JTHorizontalCalendarView!
    private let calendar = JTCalendarManager()

    override func viewDidLoad() {
        calendar.menuView = JTCalendarMenuView()
        calendar.contentView = calendarContentView
        calendar.settings.weekModeEnabled = true
        calendar.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        calendar.setDate(NSDate())
        calendar.reload()
    }
    
    @IBAction func showTrainingView(sender: AnyObject) {
        performSegueWithIdentifier("train", sender: nil)
    }
    
    // MARK: JTCalendarDelegate
    func calendar(calendar: JTCalendarManager!, prepareDayView dv: UIView!) {
        JTCalendarHelper.calendar(calendar, prepareDayView: dv, on: calendar.date()) { _ in
            return true
        }
    }
    
    func calendar(calendar: JTCalendarManager!, didTouchDayView dv: UIView!) {
        let dayView = dv as! JTCalendarDayView
        calendar.setDate(dayView.date)
    }
    
}

struct JTCalendarHelper {
    typealias HasEvent = NSDate -> Bool
    private static let dateHelper: JTDateHelper = JTDateHelper()
    
    static func calendar(calendar: JTCalendarManager!, prepareDayView dv: UIView!, on selectedDate: NSDate?, hasEvent: HasEvent) {
            
            if let dayView = dv as? JTCalendarDayView {
                // Today
                if JTCalendarHelper.dateHelper.date(selectedDate, isTheSameDayThan: dayView.date) ?? false {
                    dayView.circleView.hidden = false
                    dayView.circleView.backgroundColor = UIColor.redColor()
                    dayView.dotView.backgroundColor = UIColor.whiteColor()
                    dayView.textLabel.textColor = UIColor.whiteColor()
                } else if JTCalendarHelper.dateHelper.date(NSDate(), isTheSameDayThan: dayView.date) {
                    dayView.circleView.hidden = false
                    dayView.circleView.backgroundColor = UIColor.blueColor()
                    dayView.dotView.backgroundColor = UIColor.whiteColor()
                    dayView.textLabel.textColor = UIColor.whiteColor()
                } else {
                    dayView.circleView.hidden = true
                    dayView.dotView.backgroundColor = UIColor.redColor()
                    dayView.textLabel.textColor = UIColor.blackColor()
                }
                
                
                dayView.dotView.hidden = !hasEvent(dayView.date)
            }
    }
    
}