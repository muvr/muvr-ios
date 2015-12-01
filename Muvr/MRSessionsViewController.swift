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
    private var menuViewController: MRMenuViewController? = nil
    private var leftSwipe: UISwipeGestureRecognizer? = nil
    
    // the session view controllers of the selected date
    private var sessionViewControllers: [UIViewController] = []

    ///
    /// fetched the sessions on the given date and displays the most recent one
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
    
    func showMenu() {
        guard self.menuViewController == nil,
              let menuViewController = storyboard?.instantiateViewControllerWithIdentifier("menuViewController") as? MRMenuViewController
        else { return }
        self.menuViewController = menuViewController
        UIApplication.sharedApplication().keyWindow?.addSubview(menuViewController.view)
        //            view.insertSubview(menuViewController.view, aboveSubview: self.view)
        menuViewController.view.frame.origin.x = -self.view.frame.width
        animateMenuPosition(targetPosition: -60)
        leftSwipe = UISwipeGestureRecognizer(target: self, action: "hideMenu")
        leftSwipe?.direction = .Left
        menuViewController.view.addGestureRecognizer(leftSwipe!)
    }
    
    func hideMenu() {
        guard let menuViewController = self.menuViewController else { return }
        animateMenuPosition(targetPosition: -Float(self.view.frame.width)) { finished in
            menuViewController.view.removeFromSuperview()
            self.menuViewController = nil
            self.leftSwipe = nil
        }
    }
    
    @IBAction func toggleMenu(sender: AnyObject) {
        if menuViewController == nil {
            showMenu()
        } else {
            hideMenu()
        }
    }
    
    private func animateMenuPosition(targetPosition targetPosition: Float, completion: ((Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.menuViewController?.view.frame.origin.x = CGFloat(targetPosition)
        }, completion: completion)

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
        
        pageViewController = UIPageViewController(transitionStyle: UIPageViewControllerTransitionStyle.Scroll, navigationOrientation: UIPageViewControllerNavigationOrientation.Horizontal, options: nil)
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
