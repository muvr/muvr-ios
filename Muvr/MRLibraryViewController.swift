import MuvrKit

class MRLibraryViewController: UIViewController, UITableViewDataSource {

    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    private var workouts = MRAppDelegate.sharedDelegate().predefinedSessions
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
    
    private func clearSelection() {
        for r in 0..<workouts.count {
            let ip = NSIndexPath(forRow: r, inSection: 0)
            tableView.cellForRowAtIndexPath(ip)?.accessoryType = .None
        }
        startButton.enabled = false
        selectedWorkout = nil
    }
    
    @IBAction func startWorkout(sender: UIButton) {
        guard let workout = selectedWorkout else { return }
        try! MRAppDelegate.sharedDelegate().startSession(workout)
    }
    
}
