import Foundation

///
/// Controls a view that allows the user to provide details of the exercise session he or she
/// is about to start. 
///
/// We use these details to configure the movement and exercise deciders, and the classifiers.
///
class MRExerciseSessionAdHocViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        NSLog("Show info for cell")
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = MRApplicationState.muscleGroups[indexPath.row]
        performSegueWithIdentifier("exercise", sender: [cell.id])
    }
    
    // MARK: UITableViewDataSource
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
        cell.detailTextLabel!.text = ", ".join(data.localisedExercises.map { $0.title })
        
        return cell
    }
    
    // MARK: Transition to exercising
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let ctrl = segue.destinationViewController as? MRExerciseSessionStartable,
           let muscleGroupsIds = sender as? [String] {
            let properties = MRResistanceExerciseSession(startDate: NSDate(), intendedIntensity: 0.5, muscleGroupIds: muscleGroupsIds, title: "Ad Hoc".localized())
            ctrl.startSession(MRApplicationState.loggedInState!.startSession(properties), withPlan: nil)
        }
    }

}
