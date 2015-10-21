import UIKit
import MuvrKit

class MRSessionsViewController : UIViewController, UITableViewDataSource, MKExerciseSessionStoreDelegate {
    @IBOutlet var tableView: UITableView!
    
    @IBAction func showTrainingView(sender: AnyObject) {
        performSegueWithIdentifier("train", sender: nil)
    }
    
    @IBAction func clear(sender: UIBarButtonItem) {
    }
    
    @IBAction func share(sender: UIBarButtonItem) {
    }
    
    // MARK: UIViewController
    
    override func viewDidAppear(animated: Bool) {
        MRAppDelegate.sharedDelegate().exerciseSessionStoreDelegate = self
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return MRAppDelegate.sharedDelegate().getAllSessions().count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "session \(section)"
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MRAppDelegate.sharedDelegate().getAllSessions()[section].classifiedExercises.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let ces = MRAppDelegate.sharedDelegate().getAllSessions()[indexPath.section].classifiedExercises
        let ce = ces[indexPath.row]
        
        let cell = tableView.dequeueReusableCellWithIdentifier("classifiedExercise")!
        cell.textLabel?.text = ce.exerciseId
        return cell
    }
    
    // MARK: MKExerciseSessionStoreDelegate

    func exerciseSessionStoreChanged(store: MKExerciseSessionStore) {
        tableView.reloadData()
    }
}
