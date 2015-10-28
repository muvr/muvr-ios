import UIKit
import CoreData
import JTCalendar

///
/// Handle navigation between sessions.
/// This class manages 2 components:
///  - a calendar to select a date and fetch sessions on that date
///  - a page view to navigate sessions on the selected date
///
class MRSessionsViewController : UIViewController, UIPageViewControllerDataSource, JTCalendarDelegate {
    
    @IBOutlet weak var calendarContentView: JTHorizontalCalendarView!
    private var pageViewController: UIPageViewController!
    private let calendar = JTCalendarManager()

    // the sessions of the selected date
    private var sessionControllers: [UIViewController] = []
    // the index of the displayed session
    private var sessionIndex: Int?

    ///
    /// fetched the sessions on the given date and displays the most recent one (the one at index = 0)
    ///
    func showSessionsOn(date date: NSDate) {
        let sessions = MRManagedExerciseSession.sessionsOnDate(date, inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
        sessionControllers = sessions.map { session in
            let vc: MRSessionViewController = storyboard?.instantiateViewControllerWithIdentifier("sessionViewController") as! MRSessionViewController
            vc.setSession(session)
            return vc
        }
        pageViewController.setViewControllers([sessionControllers.first!], direction: .Forward, animated: true, completion: nil)
        pageViewController.didMoveToParentViewController(self)
    }
    
    ///
    /// callback function when the session starts
    ///  - display the currently running session
    ///
    func sessionDidStart() {
        let today = NSDate()
        calendar.setDate(today)
        showSessionsOn(date: today)
    }

    // MARK: UIViewController
    
    override func viewDidLoad() {
        let today = NSDate()
        calendar.menuView = JTCalendarMenuView()
        calendar.contentView = calendarContentView
        calendar.settings.weekModeEnabled = true
        calendar.delegate = self

        calendar.setDate(today)
        calendar.reload()
        
        pageViewController = storyboard?.instantiateViewControllerWithIdentifier("sessionPageViewController") as! UIPageViewController
        pageViewController.dataSource = self
        pageViewController.view.frame = CGRectMake(0, 180, view.frame.width, view.frame.size.height - 180)
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        
        showSessionsOn(date: today)
    }
    
    override func viewDidAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionDidStart", name: MRNotifications.CurrentSessionDidStart.rawValue, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: JTCalendarDelegate
    
    func calendar(calendar: JTCalendarManager!, prepareDayView dv: UIView!) {
        JTCalendarHelper.calendar(calendar, prepareDayView: dv, on: calendar.date()) { date in
            let dayView = dv as! JTCalendarDayView
            return MRManagedExerciseSession.hasSessionsOnDate(dayView.date, inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
        }
    }
    
    func calendar(calendar: JTCalendarManager!, didTouchDayView dv: UIView!) {
        let dayView = dv as! JTCalendarDayView
        calendar.setDate(dayView.date)
        showSessionsOn(date: dayView.date)
    }
    
    func calendar(calendar: JTCalendarManager!, canDisplayPageWithDate date: NSDate!) -> Bool {
        return date.compare(NSDate()) == .OrderedAscending
    }
    
    // MARK: UIPageViewControllerDataSource
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let x = (sessionControllers.indexOf { $0 === viewController }) {
            if x > 0 { return sessionControllers[x - 1] }
        }
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let x = (sessionControllers.indexOf { $0 === viewController }) {
            if x < sessionControllers.count - 1 { return sessionControllers[x + 1] }
        }
        return nil
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return sessionControllers.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
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
