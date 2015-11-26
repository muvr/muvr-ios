import UIKit
import MuvrKit
import CoreData

class MRLabelViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    private var start: NSDate?
    var session: MRManagedExerciseSession?
    
    //Hard-coded for now
    private let exerciseList = [
        "biceps-curl",
        "barbell-curl",
        "barbell-squat",
        "bent-arm-barbell-pullover",
        "lateral-raise",
        "lateral-pulldown-straight",
        "running-machine-hit",
        "suitcase-crunches",
        "triceps-dips",
        "triceps-extension",
        "triceps-pushdown",
        "dumbbell-bench-press",
        "dumbbell-shoulder-press",
        "vertical-swing"
    ]
    
    private var autocompleteExercises = [String]()
    
    @IBOutlet weak var exerciseId: UITextField!
    @IBOutlet weak var weight: UITextField!
    @IBOutlet weak var repetitions: UITextField!
    @IBOutlet weak var intensity: UISlider!
    @IBOutlet weak var autocompleteTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        autocompleteTableView.delegate = self
        autocompleteTableView.dataSource = self
        autocompleteTableView.scrollEnabled = true
        autocompleteTableView.hidden = true
        exerciseId.delegate = self
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let substring = (exerciseId.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        if (substring.characters.count <= 0) {
            autocompleteTableView.hidden = true
        } else {
            autocompleteTableView.hidden = false
        }
        
        autocompleteExercises = searchAutocompleteEntriesWithSubstring(substring)
        autocompleteTableView.reloadData()
        return true
    }
    
    private func isDashedSearchMatch(searchStr: String, exercise: String) -> Bool {
        return String(exercise.componentsSeparatedByString("-").map{ $0[$0.startIndex]}).rangeOfString(searchStr) != nil
    }
    
    private func isPrefixSearchMatch(searchStr: String, exercise: String) -> Bool {
        return exercise.lowercaseString.rangeOfString(searchStr) != nil
    }
    
    ///
    /// Filters the exercises to find only those that contain the given ``partialExercise``
    ///
    private func searchAutocompleteEntriesWithSubstring(partialExercise: String) -> [String] {
        let searchStr = partialExercise.lowercaseString
        let filteredExercises = exerciseList.filter { e in
            return isPrefixSearchMatch(searchStr, exercise: e) || isDashedSearchMatch(searchStr, exercise: e)
        }
        return filteredExercises.sort { x, y in
            return x.hasPrefix(searchStr) || x < y
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return autocompleteExercises.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("autocompleteRowIdentifier") as UITableViewCell!
        cell.textLabel?.text = autocompleteExercises[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedCell : UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        exerciseId.text = selectedCell.textLabel?.text
        tableView.hidden = true
    }
    
    @IBAction func startStop(sender: UIButton) {
        func doStart() {
            // start
            start = NSDate()
            print("started")
            sender.tag = 1
            sender.tintColor = UIColor.whiteColor()
            sender.setTitle("Stop", forState: UIControlState.Normal)
            sender.backgroundColor = UIColor.redColor()
        }

        func doStop() {
            // stop
            sender.tag = 0
            let l = MRManagedLabelledExercise.insertNewObject(into: session!, inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
            
            l.start = start!
            l.end = NSDate()
            l.exerciseId = exerciseId.text!
            l.intensity = Double(intensity.value) / Double(intensity.maximumValue)
            l.repetitions = repetitions.text.flatMap { UInt32($0) } ?? UInt32(0)
            l.weight = weight.text.flatMap { Double($0) } ?? Double(0)
                
            MRAppDelegate.sharedDelegate().saveContext()
        }
        
        if sender.tag == 0 {
            doStart()
        } else {
            doStop()
            // Dismiss if presented in a navigation stack
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
}
