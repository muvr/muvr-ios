import Foundation

class MRClassificationCompletedViewController : UITableViewController {
    private struct Consts {
        static let Head = 0
        static let Tail = 1
        static let Others = 2
        static let None = 3
    }
    
    private var data: NSData!
    private var simpleSets: [Int:[MRClassifiedExercise]] = [:]
    
    class func presentClassificationResult(parent: UIViewController, result: [AnyObject]!, fromData data: NSData!) -> Void {
        let ctrl: MRClassificationCompletedViewController =
            UIStoryboard(name: "Accessories", bundle: nil).instantiateViewControllerWithIdentifier("MRClassificationCompletedViewController") as! MRClassificationCompletedViewController
        var classifiedSets = result as! [MRClassifiedExerciseSet]
        classifiedSets.sort( { x, y in return x.confidence() > y.confidence() });
        
        let simple = classifiedSets.forall { $0.sets.count == 1 }
        if !simple { fatalError("Cannot yet deal with drop-sets and super-sets") }
        
        let simpleClassifiedSets = classifiedSets.map { $0.sets[0] as! MRClassifiedExercise }
        let simpleOtherSets: [MRClassifiedExercise] = [
            MRClassifiedExercise(exercise: "Bicel curl", andConfidence: 1),
            MRClassifiedExercise(exercise: "Tricep extension", andConfidence: 1),
        ]

        ctrl.simpleSets[Consts.Head] = simpleClassifiedSets.firsts
        ctrl.simpleSets[Consts.Tail] = simpleClassifiedSets.tail
        ctrl.simpleSets[Consts.Others] = simpleOtherSets
        ctrl.data = data
        
        parent.presentViewController(ctrl, animated: true, completion: nil)
    }
    
    // MARK: UITableViewController implementation
    
    // show the "head", "tail", "others"
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Consts.None {
            return 1
        } else {
            return simpleSets[section]!.count
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Consts.Head where simpleSets[section]!.count > 0: return "Best match"
        case Consts.Tail where simpleSets[section]!.count > 0: return "Alternatives"
        case Consts.Others where simpleSets[section]!.count > 0: return "Others"
        default: return nil
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == Consts.None {
            return tableView.dequeueReusableCellWithIdentifier("none")! as! UITableViewCell
        } else {
            let set = simpleSets[indexPath.section]!
            let exercise = set[indexPath.row]
            
            let cell = tableView.dequeueReusableCellWithIdentifier("simpleExercise")! as! UITableViewCell
            cell.textLabel?.text = exercise.exercise
            cell.detailTextLabel?.text = "Detail here"
            return cell
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        MRMuvrServer.sharedInstance.exerciseSessionPayload(MRUserId(), sessionId: MRSessionId(), payload: data, f: constUnit())
        dismissViewControllerAnimated(true, completion: nil)
    }
}
