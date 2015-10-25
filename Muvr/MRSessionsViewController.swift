import UIKit
import MuvrKit

class MRSessionsViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, MRExerciseStoreDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var currentSessionButton: UIBarButtonItem!
    
    // MARK: UIViewController
    
    override func viewDidAppear(animated: Bool) {
        MRAppDelegate.sharedDelegate().exerciseStoreDelegate = self
        exerciseStoreChanged()
    }
    
    override func viewDidDisappear(animated: Bool) {
        MRAppDelegate.sharedDelegate().exerciseStoreDelegate = nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let sc = segue.destinationViewController as? MRSessionViewController {
            sc.sessionId = sender as? String
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

    func exerciseStoreChanged() {
        currentSessionButton.enabled = MRAppDelegate.sharedDelegate().getCurrentSession() != nil
        tableView.reloadData()
    }
    
}
