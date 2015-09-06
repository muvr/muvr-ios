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
        performSegueWithIdentifier("exercise", sender: NSNumber(integer: indexPath.row))
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MRApplicationState.exerciseModels.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell  {
        let data = MRApplicationState.exerciseModels[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("default") as! UITableViewCell
        
        cell.textLabel!.text = data.title
        cell.detailTextLabel!.text = ", ".join(data.localisedExercises.map { $0.title })
        
        return cell
    }
    
    // MARK: Transition to exercising
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let ctrl = segue.destinationViewController as? MRExerciseSessionStartable,
           let i = sender as? NSNumber {
            let model = MRApplicationState.exerciseModels[i.integerValue]
            let properties = MRResistanceExerciseSession(startDate: NSDate(), intendedIntensity: 0.5, exerciseModel: model, title: "Ad Hoc".localized())
            ctrl.startSession(MRApplicationState.loggedInState!.startSession(properties))
        }
    }

}
