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
class MRClassificationCompletedViewController : UITableViewController {
    static let storyboardId: String = "MRClassificationCompletedViewController"
    
    private struct Consts {
        static let Head = 0
        static let Tail = 1
        static let Others = 2
        static let None = 3
    }
    
    private var data: NSData!
    private var simpleClassified: [MRResistanceExercise] = []
    private var simpleOthers: [MRResistanceExercise] = []
    private var state: MRExercisingApplicationState!
   
    func presentClassificationResult(parent: UIViewController, state: MRExercisingApplicationState, result: [AnyObject]!, fromData data: NSData!) -> Void {
        var classifiedSets = result as! [MRResistanceExerciseSet]
        classifiedSets.sort( { x, y in return x.confidence() > y.confidence() });
        
        let simple = classifiedSets.forall { $0.sets.count == 1 }
        if !simple { fatalError("Cannot yet deal with drop-sets and super-sets") }
        
        let simpleClassifiedSets = classifiedSets.map { $0.sets[0] as! MRResistanceExercise }
        let simpleOtherSets: [MRResistanceExercise] = [
            MRResistanceExercise(exercise: "Bicep curl", andConfidence: 1),
            MRResistanceExercise(exercise: "Tricep extension", andConfidence: 1),
        ]
        
        self.simpleClassified = simpleClassifiedSets
        self.simpleOthers = simpleOtherSets
        self.data = data
        self.state = state
        
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
        case Consts.Head: return simpleClassified.count > 0 ? 1 : 0;
        case Consts.Tail: return simpleClassified.count > 1 ? simpleClassified.count - 1 : 0;
        case Consts.Others: return simpleOthers.count
        case Consts.None: return 1
        default: fatalError("Match error")
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Consts.Head where simpleClassified.count > 0 : return "Best match"
        case Consts.Tail where simpleClassified.count > 1 : return "Alternatives"
        case Consts.Others where !simpleOthers.isEmpty: return "Others"
        default: return nil
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        func simpleCell(exercise: MRResistanceExercise) -> UITableViewCell {
            let cell = tableView.dequeueReusableCellWithIdentifier("simpleExercise")! as! MRClassificationCompletedTableViewCell
            cell.setExercise(MRResistanceExerciseSet(exercise))
            cell.textLabel?.text = exercise.exercise
            cell.detailTextLabel?.text = "Detail here"
            return cell
        }
        
        switch (indexPath.section, indexPath.row) {
        case (Consts.None, _): return tableView.dequeueReusableCellWithIdentifier("none")! as! MRClassificationCompletedTableViewCell
        case (Consts.Head, _): return simpleCell(simpleClassified[0])
        case (Consts.Tail, let x): return simpleCell(simpleClassified[x - 1])
        case (Consts.Others, let x): return simpleCell(simpleOthers[x])
        default: fatalError("Match error")
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! MRClassificationCompletedTableViewCell
        let exerciseSet: MRResistanceExerciseSet? = cell.getExercise()
        let example = MRResistanceExerciseSetExample(classified: simpleClassified.map { MRResistanceExerciseSet($0) }, correct: exerciseSet, fusedSensorData: data)
        state.postResistanceExample(example) { $0.cata(println, r: println) }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}
