import MuvrKit

///
/// Displays the predefined workouts in a tableview
///
class MRLibraryViewController: UIViewController, UITableViewDataSource {

    /// starts the workout
    @IBOutlet private weak var startButton: UIButton!
    /// the tableview containing the workouts
    @IBOutlet private weak var tableView: UITableView!
    /// the predefined workouts
    private var workouts = MRAppDelegate.sharedDelegate().predefinedSessions
    /// the selected workout
    private var selectedWorkout: MRSessionType? = nil
    
    // MARK: - UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        cell.textLabel?.text = workouts[indexPath.row].name
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // first, deselect all other cells in all other sections
        clearSelection()
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .Checkmark
        selectedWorkout = workouts[indexPath.row]
        startButton.enabled = true
    }
    
    ///
    /// Unselect any selected table rows
    ///
    private func clearSelection() {
        for r in 0..<workouts.count {
            let ip = NSIndexPath(forRow: r, inSection: 0)
            tableView.cellForRowAtIndexPath(ip)?.accessoryType = .None
        }
        startButton.enabled = false
        selectedWorkout = nil
    }
    
    ///
    /// Starts the selected workout
    ///
    @IBAction func startWorkout(sender: UIButton) {
        guard let workout = selectedWorkout else { return }
        try! MRAppDelegate.sharedDelegate().startSession(workout)
    }
    
}
