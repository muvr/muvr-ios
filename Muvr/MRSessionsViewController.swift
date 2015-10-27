import UIKit
import CoreData
import JTCalendar

class MRSessionsViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, UIPageViewControllerDataSource, NSFetchedResultsControllerDelegate, JTCalendarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var currentSessionButton: UIBarButtonItem!
    @IBOutlet weak var calendarContentView: JTHorizontalCalendarView!
    private var pageViewController: UIPageViewController!
   
    private let calendar = JTCalendarManager()
    
    private var sessions: [MRManagedExerciseSession] = []

    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let sessionsFetchRequest = NSFetchRequest(entityName: "MRManagedExerciseSession")
        sessionsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
        let frc = NSFetchedResultsController(
            fetchRequest: sessionsFetchRequest,
            managedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    func viewControllerAtIndex(index: Int) -> MRSessionViewController {
        let vc: MRSessionViewController = self.storyboard?.instantiateViewControllerWithIdentifier("sessionViewController") as! MRSessionViewController
        vc.setSessionId(sessions[index].objectID, sessionIndex: index)
        return vc
    }

    // MARK: UIViewController
    
    override func viewDidLoad() {
        calendar.menuView = JTCalendarMenuView()
        calendar.contentView = calendarContentView
        calendar.settings.weekModeEnabled = true
        calendar.delegate = self

        calendar.setDate(NSDate())
        calendar.reload()
        
        pageViewController = storyboard?.instantiateViewControllerWithIdentifier("sessionPageViewController") as! UIPageViewController
        pageViewController.dataSource = self
        pageViewController.view.frame = CGRectMake(0, 200, view.frame.width, view.frame.size.height - 300)
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
    }
    
    override func viewDidAppear(animated: Bool) {
        try! fetchedResultsController.performFetch()
        currentSessionButton.enabled = MRAppDelegate.sharedDelegate().currentSession != nil
        tableView.reloadData()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        currentSessionButton.enabled = MRAppDelegate.sharedDelegate().currentSession != nil
        tableView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let sc = segue.destinationViewController as? MRSessionViewController, let sessionId = sender as? NSManagedObjectID {
            sc.setSessionId(sessionId, sessionIndex: 0)
        }
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("session", forIndexPath: indexPath)
        let session = fetchedResultsController.objectAtIndexPath(indexPath) as! MRManagedExerciseSession
        
        cell.textLabel?.text = session.exerciseModelId
        cell.detailTextLabel?.text = "\(session.startDate)"
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let session = fetchedResultsController.objectAtIndexPath(indexPath) as? MRManagedExerciseSession {
            performSegueWithIdentifier("session", sender: session.objectID)
        }
    }
    
    @IBAction func showCurrentSession() {
        if let session = MRAppDelegate.sharedDelegate().currentSession {
            performSegueWithIdentifier("session", sender: session.objectID)
        }
    }
    
    // MARK: JTCalendarDelegate
    func calendar(calendar: JTCalendarManager!, prepareDayView dv: UIView!) {
        JTCalendarHelper.calendar(calendar, prepareDayView: dv, on: calendar.date()) { date in
            return true
        }
    }
    
    func calendar(calendar: JTCalendarManager!, didTouchDayView dv: UIView!) {
        let dayView = dv as! JTCalendarDayView
        calendar.setDate(dayView.date)
        
        sessions = MRManagedExerciseSession.sessionsOnDate(dayView.date, inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
        
        NSLog("Show \(sessions) on \(dayView.date)")
        
        let startVC = viewControllerAtIndex(0)
        let viewControllers = [startVC]
        pageViewController.setViewControllers(viewControllers, direction: .Forward, animated: true, completion: nil)
        pageViewController.didMoveToParentViewController(self)
    }
    
    func calendar(calendar: JTCalendarManager!, canDisplayPageWithDate date: NSDate!) -> Bool {
        return date.compare(NSDate()) == .OrderedAscending
    }
    
    // MARK: UIPageViewControllerDataSource
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? MRSessionViewController else { return nil }
        guard let index = vc.index where index > 0 else { return nil }

        return viewControllerAtIndex(index - 1)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? MRSessionViewController else { return nil }
        guard let index = vc.index where index < sessions.count - 1 else { return nil }
        
        return viewControllerAtIndex(index + 1)
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
