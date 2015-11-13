import UIKit
import MuvrKit
import CoreData

class MRLabelViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    private var start: NSDate?
    var session: MRManagedExerciseSession?
    
    //Hard-coded for now
    let exerciseList = ["alt-dumbbell-biceps-curl",
        "angle-chest-press",
        "barbell-biceps-curl",
        "barbell-press",
        "barbell-pullup",
        "biceps-curl",
        "cable-cross-overs",
        "cable-deltoid-cross-overs",
        "deltoid-row",
        "dumbbell-biceps-curl",
        "dumbbell-chest-fly",
        "dumbbell-chest-press",
        "dumbbell-front-rise",
        "dumbbell-press",
        "dumbbell-row",
        "dumbbell-side-rise",
        "lat-pulldown-angled",
        "lat-pulldown-straight",
        "lateral-raise",
        "leverage-high-row",
        "overhead-pull",
        "pulldown-crunch",
        "rope-biceps-curl",
        "rope-triceps-extension",
        "side-dips",
        "straight-bar-biceps-curl",
        "straight-bar-triceps-extension",
        "triceps-dips",
        "triceps-extension",
        "twist"]
    
    var autocompleteExercises = [String]()
    
    @IBOutlet weak var exerciseId: UITextField!
    @IBOutlet weak var weight: UITextField!
    @IBOutlet weak var repetitions: UITextField!
    @IBOutlet weak var intensity: UISlider!
    @IBOutlet var autocompleteTableView: UITableView!
    
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
        
        searchAutocompleteEntriesWithSubstring(substring)
        return true
    }
    
    /**
        Finds all exercises starting by or containing the substring.
    */
    func searchAutocompleteEntriesWithSubstring(substring: String)
    {
        autocompleteExercises.removeAll(keepCapacity: false)
        
        var prefixedExercises = exerciseList.filter({$0.hasPrefix(substring)})
        let containingExercises = exerciseList.filter({
            $0.lowercaseString.rangeOfString(substring.lowercaseString) != nil
        })
    
        for exercise in containingExercises {
            guard !prefixedExercises.contains(exercise) else {continue}
            prefixedExercises.append(exercise)
        }
        
        autocompleteExercises = prefixedExercises
        autocompleteTableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return autocompleteExercises.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let autoCompleteRowIdentifier = "AutoCompleteRowIdentifier"
        var cell = tableView.dequeueReusableCellWithIdentifier(autoCompleteRowIdentifier) as UITableViewCell?
        
        let index = indexPath.row as Int
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: autoCompleteRowIdentifier)
        }
        cell?.textLabel?.text = autocompleteExercises[index]
        return cell!
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
