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
    
    // indicates if app is currently downloading models
    private var downloadingModels: Bool = false
    
    // label showing the model's version
    private var modelVersionLabel: UILabel? = nil

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
    
    ///
    /// callback function when the session starts
    ///  - display the currently running session
    ///
    func sessionDidStart(notification: NSNotification) {
//        let today = NSDate()
//        calendar.setDate(today)
//        showSessionsOn(date: today)
        performSegueWithIdentifier("exercise", sender: notification.object)
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
        
        // refresh models button
        let buttonView = UIButton(frame: CGRectMake(0, 0, 24, 24))
        let refreshButton = UIBarButtonItem(customView: buttonView)
        buttonView.setBackgroundImage(UIImage(named: "refresh"), forState: .Normal)
        navigationItem.setRightBarButtonItems([refreshButton], animated: false)
        buttonView.addTarget(self, action: "refreshModels", forControlEvents: .TouchUpInside)
        
        displayModelVersion()
    }
    
    func refreshModels() {
        guard let refreshButton = navigationItem.rightBarButtonItems?.first?.customView else { return }
        refreshButton.rotate(0.5, delegate: self)
        self.downloadingModels = true
        MRAppDelegate.sharedDelegate().modelStore.downloadModels() {
            self.downloadingModels = false
            self.displayModelVersion()
        }
    }
    
    /// Animation callback
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        guard let refreshButton = navigationItem.rightBarButtonItems?.first?.customView else { return }
        if downloadingModels {
            // still downloading, rotate one more time
            refreshButton.rotate(0.5, delegate: self)
        }
    }
    
    func displayModelVersion() {
        // label showing version of ``arms`` model
        if modelVersionLabel == nil {
            modelVersionLabel = UILabel(frame: CGRectMake(0, 0, 32, 24))
            let modelVersionButton = UIBarButtonItem(customView: modelVersionLabel!)
            modelVersionLabel?.font = UIFont.systemFontOfSize(12)
            navigationItem.setLeftBarButtonItem(modelVersionButton, animated: false)
        }
        self.modelVersionLabel?.text = (MRAppDelegate.sharedDelegate().modelStore.models["arms"]?.version).map { return "v \($0)" }
    }
    
    override func viewDidAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionDidStart:", name: MRNotifications.CurrentSessionDidStart.rawValue, object: nil)
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
