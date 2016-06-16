import MuvrKit

class MRLibraryInfoButton: UIButton {

    var workout: MRSessionType?
    
}

class MRLibaryWorkoutCell: UITableViewCell {

    private weak var infoButton: MRLibraryInfoButton!
    
}

///
/// Displays the predefined workouts in a tableview
///
class MRLibraryViewController: UIViewController, UITableViewDataSource {

    /// starts the workout
    @IBOutlet private weak var startButton: UIButton!
    /// the tableview containing the workouts
    @IBOutlet private weak var tableView: UITableView!
    /// the predefined workouts
    private var workouts = MRAppDelegate.sharedDelegate().predefinedSessionTypes
    /// the selected workout
    private var selectedWorkout: MRSessionType? = nil
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! MRLibaryWorkoutCell
        cell.textLabel?.text = workouts[indexPath.row].name
        cell.textLabel?.backgroundColor = .clearColor()
        cell.infoButton.workout = workouts[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // first, deselect all other cells in all other sections
        clearSelection()
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .Checkmark
        selectedWorkout = workouts[indexPath.row]
        startButton.isEnabled = true
    }
    
    ///
    /// Unselect any selected table rows
    ///
    private func clearSelection() {
        for r in 0..<workouts.count {
            let ip = IndexPath(row: r, section: 0)
            tableView.cellForRow(at: ip)?.accessoryType = .none
        }
        startButton.isEnabled = false
        selectedWorkout = nil
    }
    
    ///
    /// Starts the selected workout
    ///
    @IBAction func startWorkout(_ sender: UIButton) {
        guard let workout = selectedWorkout else { return }
        try! MRAppDelegate.sharedDelegate().startSession(workout)
    }
    
    ///
    /// Shows the workout description
    /// (workout descriptions are stored as HTML files)
    ///
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let webView = segue.destinationViewController.view as? UIWebView,
              let button = sender as? MRLibraryInfoButton,
              let workout = button.workout,
              case .predefined(let plan) = workout,
              let bundlePath = Bundle(for: MRAppDelegate.self).pathForResource("Sessions", ofType: "bundle"),
              let bundle = Bundle(path: bundlePath),
              let path = bundle.pathForResource(plan.filename, ofType: "html", inDirectory: "www"),
              let url = URL(string: path)
        else { return }
        
        let request = URLRequest(url: url)
        webView.loadRequest(request)
    }
    
}
