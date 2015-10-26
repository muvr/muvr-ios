import UIKit
import CoreData

class MRSessionsViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var currentSessionButton: UIBarButtonItem!
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
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

    // MARK: UIViewController
    
    override func viewDidAppear(animated: Bool) {
        try! fetchedResultsController.performFetch()
        tableView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let sc = segue.destinationViewController as? MRSessionViewController, let sessionId = sender as? NSManagedObjectID {
            sc.setSessionId(sessionId)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        currentSessionButton.enabled = MRAppDelegate.sharedDelegate().currentSession != nil
        tableView.reloadData()
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
    
}
