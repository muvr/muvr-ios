import Foundation

///
/// A UITableViewCell that adds a reference to the exercise being classified.
///
class MRClassificationCompletedTableViewCell : UITableViewCell {
    private var exercise: AnyObject?
    
    func getExercise<A>() -> A? {
        return exercise as! A?
    }
    
    func getClassifiedResistanceExercise() -> MRClassifiedResistanceExercise? {
        if let e = exercise as? MRResistanceExercise { return MRClassifiedResistanceExercise(e) }
        
        return nil
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
        static let Others = 2
        static let None = 3
    }
    
    @IBOutlet var progressView: MRResistanceExerciseProgressView!
    
    private var data: NSData!
    private var userClassification: MRExerciseSessionUserClassification!
    private var onComplete: ((MRResistanceExerciseExample, NSData) -> Void)!
   
    func presentClassificationResult(parent: UIViewController, userClassification: MRExerciseSessionUserClassification, onComplete: ((MRResistanceExerciseExample, NSData) -> Void)) -> Void {
        self.userClassification = userClassification
        self.data = userClassification.data
        self.onComplete = onComplete
        
        tableView.reloadData()
        parent.presentViewController(self, animated: true, completion: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let f = userClassification.combined.first {
            progressView.setTime(Int(f.time), max: 60)
            progressView.setRepetitions(f.repetitions?.integerValue ?? 0, max: 20)
            progressView.setText(f.resistanceExercise.title)
        }
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
        case Consts.Head: return userClassification.classified.count > 0 ? 1 : 0
        case Consts.Tail: return userClassification.classified.count > 1 ? userClassification.classified.count - 1 : 0
        case Consts.Others: return userClassification.other.count
        case Consts.None: return 1
        default: fatalError("Match error")
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Consts.Head where userClassification.classified.count > 0 : return "Best match".localized()
        case Consts.Tail where userClassification.classified.count > 1 : return "Alternatives".localized()
        case Consts.Others where !userClassification.other.isEmpty: return "Others".localized()
        default: return nil
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        func simpleCell(exercise: MRResistanceExercise) -> UITableViewCell {
            let cell = tableView.dequeueReusableCellWithIdentifier("simpleExercise")! as! MRClassificationCompletedTableViewCell
            cell.setExercise(exercise)
            cell.textLabel?.text = exercise.title
            cell.detailTextLabel?.text = "Detail here"
            return cell
        }
        
        switch (indexPath.section, indexPath.row) {
        case (Consts.None, _): return tableView.dequeueReusableCellWithIdentifier("none")! as! MRClassificationCompletedTableViewCell
        case (Consts.Head, _): return simpleCell(userClassification.classified[0].resistanceExercise)
        case (Consts.Tail, let x): return simpleCell(userClassification.classified[x + 1].resistanceExercise)
        case (Consts.Others, let x): return simpleCell(userClassification.other[x])
        default: fatalError("Match error")
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! MRClassificationCompletedTableViewCell
        let exercise = cell.getClassifiedResistanceExercise()
        let example = MRResistanceExerciseExample(classified: userClassification.classified, correct: exercise)
        dismissViewControllerAnimated(true, completion: nil)
        
        onComplete(example, data)
    }
}
