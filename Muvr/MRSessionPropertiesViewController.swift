import Foundation

class MRSessionPropertiesViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet
    var tableView: UITableView!
    
    // #pragma mark - UITableViewDelegate
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        NSLog("Show info for cell")
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = MRApplicationState.muscleGroups[indexPath.row]
        performSegueWithIdentifier("exercise", sender: [cell.id])
    }
    
    // #pragma mark - UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MRApplicationState.muscleGroups.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell  {
        let data = MRApplicationState.muscleGroups[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("default") as! UITableViewCell
        
        cell.textLabel!.text = data.title
        cell.detailTextLabel!.text = ", ".join(data.exercises)
        
        return cell
    }
    
    // #pragma MARK - the rest
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let ctrl = segue.destinationViewController as? MRExerciseViewController,
           let muscleGroupsIds = sender as? [String] {
            ctrl.startExercising(muscleGroupsIds)
        }
    }

}