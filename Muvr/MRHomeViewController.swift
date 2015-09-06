import Foundation
import JTCalendar

class MRHomeViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, JTCalendarDelegate, UIActionSheetDelegate {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var calendarContentView: JTHorizontalCalendarView!
    @IBOutlet var profileItem: UIBarItem!
    
    private let calendar = JTCalendarManager()
    private var resistanceExerciseSessions: [MRResistanceExerciseSession] = []
    private var resistanceExerciseSessionDetails: [MRResistanceExerciseSessionDetail] = []
    
    private struct Consts {
        static let Sessions = 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //calendar.delegate = self
        calendar.menuView = JTCalendarMenuView()
        calendar.contentView = calendarContentView
        calendar.settings.weekModeEnabled = true
        calendar.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // tidy up the data
        MRDataModel.cleanup()

        // sync the data to the server
        MRApplicationState.loggedInState!.sync();
        
        // load the view data
        resistanceExerciseSessions = MRApplicationState.loggedInState!.getResistanceExerciseSessions()
        calendar.setDate(NSDate())
        calendar.reload()
        refreshCalendar(on: calendar.date())
        
        // set up UI controls
        profileItem.enabled = !MRApplicationState.loggedInState!.isAnonymous
    }
    
    @IBAction func editProfile() -> Void {
        performSegueWithIdentifier("profile", sender: nil)
    }
    
    @IBAction func settings() -> Void {
        let accountActionTitle = MRApplicationState.loggedInState!.isAnonymous ? "Register" : "Logout"
        let menu = UIActionSheet(title: nil, delegate: self,
            cancelButtonTitle: "Cancel".localized(),
            destructiveButtonTitle: accountActionTitle.localized(),
            otherButtonTitles: "Synchronize".localized(), "Reset Training Data".localized())
        menu.showFromTabBar(tabBarController?.tabBar)
    }
    
    // MARK: UIActionSheetDelegate
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        switch buttonIndex {
        case 0: // Destructive: logout or register
            performSegueWithIdentifier("logout", sender: self)
        case 2: // Synchronize
            MRApplicationState.loggedInState!.sync()
        case 3: // Reset training
            MRApplicationState.clearTrainingData()
        default: // noop
            return
        }
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Consts.Sessions: return resistanceExerciseSessionDetails.count
        default: fatalError("Match error")
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (Consts.Sessions, let x):
            let ((_, session), exercises) = resistanceExerciseSessionDetails[x]
            let cell = tableView.dequeueReusableCellWithIdentifier("session") as! MRResistanceExerciseSetTableViewCell
            cell.setSession(session, andExercises: exercises)
            return cell
        default:
            fatalError(":(")
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case Consts.Sessions: return 100
        default: return 44
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Consts.Sessions: return "Sessions".localized()
        default: fatalError("Match error")
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (Consts.Sessions, let x):
            // TODO: view session
            return
        default: fatalError("Match error")
        }
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        switch indexPath.section {
        case Consts.Sessions: return UITableViewCellEditingStyle.Delete
        default: return UITableViewCellEditingStyle.None
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            switch (indexPath.section, indexPath.row) {
            case (Consts.Sessions, let x):
                let ((id, _), _) = resistanceExerciseSessionDetails[x]
                MRApplicationState.loggedInState!.deleteSession(id)
                resistanceExerciseSessions = MRApplicationState.loggedInState!.getResistanceExerciseSessions()
                
                refreshCalendar(on: calendar.date())
                calendar.reload()
                tableView.reloadData()
            default:
                // noop
                return
            }
        }
    }
    
    private func refreshCalendar(on date: NSDate) {
        resistanceExerciseSessionDetails = MRApplicationState.loggedInState!.getResistanceExerciseSessionDetails(on: date)
        calendar.setDate(date)
        tableView.reloadData()
    }
    
    // MARK: JTCalendarDelegate
    func calendar(calendar: JTCalendarManager!, prepareDayView dv: UIView!) {
        JTCalendarHelper.calendar(calendar, prepareDayView: dv, on: calendar.date()) { date in
            self.resistanceExerciseSessions.find { elem in elem.startDate.dateOnly == date } != nil
        }
    }
    
    func calendar(calendar: JTCalendarManager!, didTouchDayView dv: UIView!) {
        let dayView = dv as! JTCalendarDayView
        refreshCalendar(on: dayView.date)
    }
    
    // MARK: Transition to exercising
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
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
