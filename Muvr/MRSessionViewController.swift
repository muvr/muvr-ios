import UIKit
import CoreData

class MRSessionViewController : UIViewController, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    //private var fetchedResultsController: NSFetchedResultsController?
    private var session: MRManagedExerciseSession?
    
    func setSessionId(sessionId: NSManagedObjectID) {
        session = try? MRAppDelegate.sharedDelegate().managedObjectContext.existingObjectWithID(sessionId) as! MRManagedExerciseSession
    }
    
    func share(data: NSData, fileName: String) {
        let documentsUrl = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        let fileUrl = NSURL(fileURLWithPath: documentsUrl).URLByAppendingPathComponent(fileName)
        if data.writeToURL(fileUrl, atomically: true) {
            let controller = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
            let excludedActivities = [UIActivityTypePostToTwitter, UIActivityTypePostToFacebook,
                UIActivityTypePostToWeibo, UIActivityTypeMessage, UIActivityTypeMail,
                UIActivityTypePrint, UIActivityTypeCopyToPasteboard,
                UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr,
                UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo]
            controller.excludedActivityTypes = excludedActivities
            
            presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    // MARK: Share & label
    @IBAction func shareRaw() {
//        if let data = session?.sensorData?.encode() {
//            share(data, fileName: "sensordata.raw")
//        }
    }
    
    @IBAction func shareCSV() {
//        if let data = session?.sensorData?.encodeAsCsv(labelledExercises: labelledExercises) {
//            share(data, fileName: "sensordata.csv")
//        }
    }
    
    @IBAction func label(sender: UIBarButtonItem) {
        performSegueWithIdentifier("label", sender: session)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let lc = segue.destinationViewController as? MRLabelViewController, let session = sender as? MRManagedExerciseSession {
            lc.session = session
        }
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Classified Exercises"
        case 1: return "Labels"
        default: return nil
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return session?.classifiedExercises.count ?? 0
        case 1: return session?.labelledExercises.count ?? 0
        default: return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("classifiedExercise", forIndexPath: indexPath)
        cell.textLabel!.text = "some such"
        return cell
    }
    
}
