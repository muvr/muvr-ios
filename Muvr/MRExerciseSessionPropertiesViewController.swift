import Foundation

///
/// Controls a view that allows the user to provide details of the exercise session he or she
/// is about to start. 
///
/// We use these details to configure the movement and exercise deciders, and the classifiers.
///
class MRSessionPropertiesViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet
    var tableView: UITableView!
    
    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        NSLog("Show info for cell")
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = MRApplicationState.localisedMuscleGroups[indexPath.row]
        performSegueWithIdentifier("exercise", sender: [cell.id])
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MRApplicationState.localisedMuscleGroups.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell  {
        let data = MRApplicationState.localisedMuscleGroups[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("default") as! UITableViewCell
        
        cell.textLabel!.text = data.title
        cell.detailTextLabel!.text = ", ".join(data.exercises.map { $0.title })
        
        return cell
    }
    
    // MARK: Transition to exercising
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let ctrl = segue.destinationViewController as? MRExerciseSessionViewController,
           let muscleGroupsIds = sender as? [String] {
            let properties = MRResistanceExerciseSessionProperties(intendedIntensity: 1, muscleGroupIds: muscleGroupsIds)
            ctrl.startSession(MRApplicationState.loggedInState!.startSession(properties), withPlan: MRExercisePlan.adHoc())
        }
    }

}
