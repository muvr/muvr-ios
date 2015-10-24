import UIKit
import MuvrKit

class MRSessionViewController : UIViewController, UITableViewDataSource, MKExerciseSessionStoreDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    private var session: MKExerciseSession?
    var filter: ExerciseSessionFilter? {
        didSet {
            updateSession()
        }
    }

    enum ExerciseSessionFilter {
        case Current
        case Recorded(id: String)
    }
    
    private func updateSession() {
        switch filter {
        case .Some(.Current):
            session = MRAppDelegate.sharedDelegate().getCurrentSession()
        case .Some(.Recorded(let id)):
            session = MRAppDelegate.sharedDelegate().getSessionById(id)
        default:
            session = nil
        }
    }
    
    func exerciseSessionStoreChanged(store: MKExerciseSessionStore) {
        updateSession()
    }

    // MARK: UIViewController
    override func viewDidAppear(animated: Bool) {
        MRAppDelegate.sharedDelegate().exerciseSessionStoreDelegate = self
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
        return session?.classifiedExercises.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, let row):
            let ce = session!.classifiedExercises[row]
            let cell = tableView.dequeueReusableCellWithIdentifier("classifiedExercise")!
            cell.textLabel!.text = ce.exerciseId
            return cell
        case (1, _): fatalError("Fixme")
        default: fatalError("Fixme")
        }
    }
    
}
