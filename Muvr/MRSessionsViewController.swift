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

    // the session view controllers of the selected date
    private var sessionViewControllers: [UIViewController] = []
    
    ///
    /// Fetches the sessions on the given date and displays the most recent one
    ///
    func showSessionsOn(date date: NSDate) {
        let sessions = MRManagedExerciseSession.sessionsOnDate(date, inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
        sessionViewControllers = sessions.map { session in
            let vc: MRSessionViewController = storyboard?.instantiateViewControllerWithIdentifier("sessionViewController") as! MRSessionViewController
            vc.setSession(session)
            return vc
        }
        if !sessions.isEmpty {
            pageViewController.setViewControllers([sessionViewControllers.first!], direction: .Forward, animated: true, completion: nil)
        } else {
            let emptyViewController = storyboard?.instantiateViewControllerWithIdentifier("sessionViewController") as! MRSessionViewController
            pageViewController.setViewControllers([emptyViewController], direction: .Forward, animated: true, completion: nil)
        }
        pageViewController.didMoveToParentViewController(self)
    }
    
    ///
    /// Local notification callback function intended to be used when the session starts.
    /// - parameter notification: the details of the local notification
    ///
    func sessionDidStart(notification: NSNotification) {
        performSegueWithIdentifier("exercise", sender: notification.object)
    }
    
    ///
    /// Local notification callback function intended to be used when location is set.
    /// - parameter notification: the details of the local notification
    ///
    func locationDidObtain(notification: NSNotification) {
        if let locationName = notification.object as? String {
            title = locationName
        } else {
            title = "Muvr"
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let svc = segue.destinationViewController as? MRSessionViewController,
           let session = MRAppDelegate.sharedDelegate().managedObjectContext.objectWithID(sender as! NSManagedObjectID) as? MRManagedExerciseSession {
            svc.navigationItem.hidesBackButton = true
            svc.setSession(session)
        }
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
        
        pageViewController = UIPageViewController(transitionStyle: UIPageViewControllerTransitionStyle.Scroll, navigationOrientation: UIPageViewControllerNavigationOrientation.Horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.view.frame = CGRectMake(0, 100, view.frame.width, view.frame.size.height - 100)
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        
        showSessionsOn(date: today)
    }
    
    override func viewDidAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionDidStart:", name: MRNotifications.CurrentSessionDidStart.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "locationDidObtain:", name: MRNotifications.LocationDidObtain.rawValue, object: nil)
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
    
    // MARK: UIPageViewControllerDataSource
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let x = (sessionViewControllers.indexOf { $0 === viewController }) {
            if x > 0 { return sessionViewControllers[x - 1] }
        }
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let x = (sessionViewControllers.indexOf { $0 === viewController }) {
            if x < sessionViewControllers.count - 1 { return sessionViewControllers[x + 1] }
        }
        return nil
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return sessionViewControllers.count
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
