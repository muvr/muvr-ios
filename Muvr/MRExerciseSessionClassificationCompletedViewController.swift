import Foundation

///
/// A UITableViewCell that adds a reference to the exercise being classified.
///
class MRClassificationCompletedTableViewCell : UITableViewCell {
    private var exercise: AnyObject?
    
    func getExercise<A>() -> A? {
        return exercise as! A?
    }
    
    func setExercise(exercise: AnyObject?) {
        self.exercise = exercise
    }
}

///
/// Controls a view that can be presented when the ``MRClassificationPipelineDelegate``'s methods are called,
/// allowing the users to provide feedback on the classification.
///
/// TODO: Provide an interface to some device that can provide the feedback without the users having to use the phone
///
class MRExerciseSessionClassificationCompletedViewController : UITableViewController {
    static let storyboardId: String = "MRExerciseSessionClassificationCompletedViewController"
    
    private struct Consts {
        static let Head = 0
        static let Tail = 1
        static let Planned = 2
        static let Others = 3
        static let None = 4
    }
    
    private var data: NSData!
    private var simpleClassified: [MRResistanceExercise] = []
    private var simpleOthers: [MRResistanceExercise] = []
    private var simplePlanned: MRResistanceExercise? = nil
    private var onComplete: (MRResistanceExerciseSetExample -> Void)!
   
    func presentClassificationResult(parent: UIViewController, userClassification: MRExerciseSessionUserClassification, fromData data: NSData!, onComplete: MRResistanceExerciseSetExample -> Void) -> Void {
        self.simpleClassified = userClassification.simpleClassifiedSets
        self.simpleOthers = userClassification.simpleOtherSets
        self.simplePlanned = userClassification.simplePlannedSet
        self.data = data
        self.onComplete = onComplete
        
        tableView.reloadData()
        parent.presentViewController(self, animated: true, completion: nil)
    }
    
    // MARK: UITableViewController implementation
    
    ///
    /// We have four sections. We hope that the first element in the classified results is indeed 
    /// the exercise that the user has performed. 
    ///
    /// - the most likely outcome: Consts.Head
    /// - the alternatives: Consts.Tail
    /// - the others: Consts.Others
    /// - completely wrong: Consts.None
    ///
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Consts.Head: return simpleClassified.count > 0 ? 1 : 0
        case Consts.Tail: return simpleClassified.count > 1 ? simpleClassified.count - 1 : 0
        case Consts.Planned: return simplePlanned != nil ? 1 : 0
        case Consts.Others: return simpleOthers.count
        case Consts.None: return 1
        default: fatalError("Match error")
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Consts.Head where simpleClassified.count > 0 : return "Best match".localized()
        case Consts.Tail where simpleClassified.count > 1 : return "Alternatives".localized()
        case Consts.Planned where simplePlanned != nil: return "Planned".localized()
        case Consts.Others where !simpleOthers.isEmpty: return "Others".localized()
        default: return nil
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        func simpleCell(exercise: MRResistanceExercise) -> UITableViewCell {
            let cell = tableView.dequeueReusableCellWithIdentifier("simpleExercise")! as! MRClassificationCompletedTableViewCell
            cell.setExercise(MRResistanceExerciseSet(exercise))
            cell.textLabel?.text = exercise.localisedTitle
            cell.detailTextLabel?.text = "Detail here"
            return cell
        }
        
        switch (indexPath.section, indexPath.row) {
        case (Consts.None, _): return tableView.dequeueReusableCellWithIdentifier("none")! as! MRClassificationCompletedTableViewCell
        case (Consts.Head, _): return simpleCell(simpleClassified[0])
        case (Consts.Planned, _): return simpleCell(simplePlanned!)
        case (Consts.Tail, let x): return simpleCell(simpleClassified[x - 1])
        case (Consts.Others, let x): return simpleCell(simpleOthers[x])
        default: fatalError("Match error")
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! MRClassificationCompletedTableViewCell
        let exerciseSet: MRResistanceExerciseSet? = cell.getExercise()
        let example = MRResistanceExerciseSetExample(classified: simpleClassified.map { MRResistanceExerciseSet($0) }, correct: exerciseSet, fusedSensorData: data)
        dismissViewControllerAnimated(true, completion: nil)
        
        onComplete(example)
    }
}
