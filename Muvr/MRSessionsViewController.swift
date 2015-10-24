import UIKit
import MuvrKit

class MRSessionsViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, MKExerciseSessionStoreDelegate, MRLabelledExerciseDelegate {
    @IBOutlet var tableView: UITableView!
    
    // MARK: UIViewController
    
    override func viewDidAppear(animated: Bool) {
        MRAppDelegate.sharedDelegate().exerciseSessionStoreDelegate = self
    }
    
    override func viewDidDisappear(animated: Bool) {
        MRAppDelegate.sharedDelegate().exerciseSessionStoreDelegate = nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let sc = segue.destinationViewController as? MRSessionViewController {
            let filter = (sender as? String)
                .map { MRSessionViewController.ExerciseSessionFilter.Recorded(id: $0) } ?? MRSessionViewController.ExerciseSessionFilter.Current
            sc.filter = filter
        }
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MRAppDelegate.sharedDelegate().getAllSessions().count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let session = MRAppDelegate.sharedDelegate().getAllSessions()[indexPath.section]
        
        let cell = tableView.dequeueReusableCellWithIdentifier("session")!
        cell.textLabel?.text = session.exerciseModelId
        return cell
    }
    
    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let session = MRAppDelegate.sharedDelegate().getAllSessions()[indexPath.section]
        performSegueWithIdentifier("session", sender: session.id)
    }
    
    @IBAction func showCurrentSession() {
        performSegueWithIdentifier("session", sender: nil)
    }
    
    // MARK: MKExerciseSessionStoreDelegate

    func exerciseSessionStoreChanged(store: MKExerciseSessionStore) {
        tableView.reloadData()
    }
    
    // MARK: MRLabelledExerciseDelegate
    
    func labelledExerciseDidAdd(labelledExercise: MKLabelledExercise) {
        // TODO: complete me
        NSLog("Added \(labelledExercise)")
    }
}
