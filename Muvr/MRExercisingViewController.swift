import UIKit
import MuvrKit

///
/// Handles the in-session explicit exercise
///
class MRExercisingViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var timedView: MRTimedView!
    
    static let cellHeight = CGFloat(80)
    
    /// The controller's state
    private enum State {
        /// 4..3..2... go!
        case CountingDown
        /// started exercising at the given ``start``
        /// - parameter start: the exercise start for future labelling
        case Exercising(start: NSDate)
        /// done exercising: whatever label is going to be added, it happened between ``start`` for ``duration``
        /// - parameter start: the start of the label
        /// - parameter duration: the duration of the label
        case Done(start: NSDate, duration: NSTimeInterval, labelling: Bool)
    }

    private var state: State = State.CountingDown
    var session: MRManagedExerciseSession!
    
    override func viewDidLoad() {
        timedView.setColourScheme(MRColourSchemes.amber)
        timedView.elapsedResets = false
        timedView.buttonTouchResets = false
        tableView.registerNib(MRExerciseTableViewCell.nib, forCellReuseIdentifier: MRExerciseTableViewCell.cellReuseIdentifier)
    }
    
    override func viewDidAppear(animated: Bool) {
        if case .CountingDown = state {
            tableView.allowsSelection = false
            timedView.setConstantTitle(NSLocalizedString("ready", comment: "get ready"))
            timedView.start(5, onTimerElapsed: beginExercising)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionDidEstimate", name: MRNotifications.SessionDidEstimate.rawValue, object: nil)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
        
    ///
    /// This is a notification callback from the sessionDidEstimate. Do not call explicitly.
    ///
    func sessionDidEstimate() {
        tableView.reloadData()
    }
    
    private func beginExercising(tv: MRTimedView) {
        timedView.setColourScheme(MRColourSchemes.red)
        timedView.countingStyle = .Elapsed
        timedView.setConstantTitle(NSLocalizedString("done", comment: "done exercising"))
        timedView.buttonTouched = stopExercising
        timedView.start(60)
        
        changeState(.Exercising(start: NSDate()))
    }
    
    private func stopExercising(tv: MRTimedView) {
        if case .Exercising(let start) = state {
            session.endExercise()
            
            timedView.setColourScheme(MRColourSchemes.green)
            timedView.setConstantTitle(NSLocalizedString("✓", comment: "exercise ticked"))
            timedView.countingStyle = .Remaining
            timedView.start(15, onTimerElapsed: ignoreLabel)
            
            changeState(.Done(start: start, duration: NSDate().timeIntervalSinceDate(start), labelling: false))
        }
    }
    
    private func popView() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    private func ignoreLabel(tv: MRTimedView) {
        if case .Done(_, _, let selecting) = state where !selecting {
            popView()
        }
    }
    
    private func changeState(newState: State) {
        state = newState
        switch newState {
        case .CountingDown:
            tableView.allowsSelection = false
            break
        case .Exercising(_):
            session.beginExercising()
            tableView.reloadData()
            break
        case .Done(_, _, _):
            tableView.allowsSelection = true
            tableView.reloadData()
            break
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 0
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        fatalError()
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        fatalError()
    }

}
