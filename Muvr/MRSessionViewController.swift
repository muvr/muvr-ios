import UIKit
import MuvrKit

class MRSessionViewController : UIViewController, UITableViewDataSource, MKExerciseSessionStoreDelegate, MRLabelledExerciseDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    private var labelledExercises: [MKLabelledExercise] = []
    private var session: MKExerciseSession?
    var filter: ExerciseSessionFilter? {
        didSet {
            exerciseSessionStoreChanged(MRAppDelegate.sharedDelegate())
        }
    }

    enum ExerciseSessionFilter {
        case Current
        case Recorded(id: String)
    }
    
    func exerciseSessionStoreChanged(store: MKExerciseSessionStore) {
        switch filter {
        case .Some(.Current):
            session = MRAppDelegate.sharedDelegate().getCurrentSession()
        case .Some(.Recorded(let id)):
            session = MRAppDelegate.sharedDelegate().getSessionById(id)
        default:
            session = nil
        }
        
        if tableView != nil { tableView.reloadData() }
    }
    
    // MARK: Share & label
    @IBAction func share(sender: UIBarButtonItem) {
        
    }
    
    @IBAction func label(sender: UIBarButtonItem) {
        performSegueWithIdentifier("label", sender: nil)
    }
    
    // MARK: MRLabelledExerciseDelegate
    func labelledExerciseDidAdd(labelledExercise: MKLabelledExercise) {
        labelledExercises.append(labelledExercise)
        tableView.reloadData()
    }

    // MARK: UIViewController
    override func viewDidAppear(animated: Bool) {
        MRAppDelegate.sharedDelegate().exerciseSessionStoreDelegate = self
        exerciseSessionStoreChanged(MRAppDelegate.sharedDelegate())
    }
    
    override func viewDidDisappear(animated: Bool) {
        MRAppDelegate.sharedDelegate().exerciseSessionStoreDelegate = nil
    }

    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Classified Exercises"
        case 1: return "Labels"
        default: return nil
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return session?.classifiedExercises.count ?? 0
        case 1: return labelledExercises.count
        default: return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, let row):
            let ce = session!.classifiedExercises[row]
            let cell = tableView.dequeueReusableCellWithIdentifier("classifiedExercise")!
            cell.textLabel!.text = ce.exerciseId
            return cell
        case (1, let row):
            let le = labelledExercises[row]
            let cell = tableView.dequeueReusableCellWithIdentifier("labelledExercise")!
            cell.textLabel!.text = le.exerciseId
            return cell

        default: fatalError("Fixme")
        }
    }
    
}
