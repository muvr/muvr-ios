import UIKit
import CoreData
import JTCalendar

///
///
///
class MRSessionsViewController : UIViewController, UIPageViewControllerDataSource, JTCalendarDelegate {
    
    @IBOutlet weak var calendarContentView: JTHorizontalCalendarView!
    private var pageViewController: UIPageViewController!
   
    private let calendar = JTCalendarManager()
    
    private var sessions: [MRManagedExerciseSession] = []

    func showSessionsOn(date date: NSDate) {
        sessions = MRManagedExerciseSession.sessionsOnDate(date, inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
        
        NSLog("Show \(sessions) on \(date)")
        
        let startVC = viewControllerAtIndex(0)
        let viewControllers = [startVC]
        pageViewController.setViewControllers(viewControllers, direction: .Forward, animated: true, completion: nil)
        pageViewController.didMoveToParentViewController(self)
    }
    
    func viewControllerAtIndex(index: Int?) -> MRSessionViewController {
        let vc: MRSessionViewController = storyboard?.instantiateViewControllerWithIdentifier("sessionViewController") as! MRSessionViewController
        if let index = index where index >= 0 && index < sessions.count {
            vc.setSessionId(sessions[index], sessionIndex: index)
        }
        return vc
    }
    
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
        pageViewController.view.frame = CGRectMake(0, 200, view.frame.width, view.frame.size.height - 200)
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
            let sessions = MRManagedExerciseSession.sessionsOnDate(dayView.date, inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
            return !sessions.isEmpty
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
        guard let vc = viewController as? MRSessionViewController,
              let i = vc.index where i > 0 else { return nil }
        return viewControllerAtIndex(i - 1)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? MRSessionViewController,
              let i = vc.index where i < sessions.count - 1 else { return nil }
        return viewControllerAtIndex(i + 1)
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return sessions.count
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
