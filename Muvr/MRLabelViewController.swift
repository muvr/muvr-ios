import UIKit
import MuvrKit
import CoreData

///
/// Provides the UI for attaching labels to specified time periods. Used in the training mode, where the users
/// fill in the details of the exercise they are about to begin, press the _start_ button, wait for the countdown
/// to finish, perform the exercise, and then click _stop_.
///
class MRLabelViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    private var start: NSDate?
    var session: MRManagedExerciseSession?
    
    //Hard-coded for now
    private var exerciseList: [MKExerciseId] = []
    
    private var autocompleteExercises = [String]()
    
    @IBOutlet weak var exerciseId: UITextField!
    @IBOutlet weak var weight: UITextField!
    @IBOutlet weak var repetitions: UITextField!
    @IBOutlet weak var intensity: UISlider!
    @IBOutlet weak var autocompleteTableView: UITableView!
    @IBOutlet weak var startButton: UIButton!
    private var timer: NSTimer? = nil
    private var counter = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let session = session {
            exerciseList = MRAppDelegate.sharedDelegate().exerciseIds(model: session.exerciseModelId)
        }
        autocompleteTableView.delegate = self
        autocompleteTableView.dataSource = self
        autocompleteTableView.scrollEnabled = true
        autocompleteTableView.hidden = true
        exerciseId.delegate = self
        exerciseId.returnKeyType = UIReturnKeyType.Done
        repetitions.returnKeyType = UIReturnKeyType.Done
        weight.returnKeyType = UIReturnKeyType.Done
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let substring = (exerciseId.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        autocompleteTableView.hidden = substring.characters.count <= 0
        autocompleteExercises = searchAutocompleteEntriesWithSubstring(substring)
        autocompleteTableView.reloadData()
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        hideKeyboard()
        return false
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
    
    private func hideKeyboard() {
        self.view.subviews.forEach { v in
            if let textField = v as? UITextField where textField.isFirstResponder() {
                textField.resignFirstResponder()
            }
        }
        autocompleteTableView.hidden = true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        hideKeyboard()
        super.touchesBegan(touches, withEvent: event)
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
        exerciseId.resignFirstResponder()
    }
    
    func updateCounter() {
        startButton.setTitle("\(counter)", forState: UIControlState.Normal)
        startButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        startButton.tintColor = UIColor.whiteColor()
        startButton.enabled = false
        if counter == 0 {
            timer?.invalidate()
            doStart()
            return
        }
        counter--
    }
    
    private func doStart() {
        start = NSDate()
        startButton.tag = 1
        startButton.tintColor = UIColor.whiteColor()
        startButton.setTitle("Stop", forState: UIControlState.Normal)
        startButton.backgroundColor = UIColor.redColor()
        startButton.enabled = true
        self.navigationItem.hidesBackButton = true
    }
    
    @IBAction func startStop(sender: UIButton) {
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
            
            NSLog("start = \(l.start.formatTime())")
            NSLog("end = \(l.end.formatTime())")
            MRAppDelegate.sharedDelegate().saveContext()
        }
        
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector: Selector("updateCounter"), userInfo: nil, repeats: true)
            counter = 5
        }
        
        if sender.tag == 1 {
            doStop()
            // Dismiss if presented in a navigation stack
            self.navigationController?.popViewControllerAnimated(true)
        }
        
        hideKeyboard()
    }
}
