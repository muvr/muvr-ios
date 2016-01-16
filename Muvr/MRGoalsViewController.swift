import UIKit
import MuvrKit

class MRGoalsViewController : UIViewController {
    
    @IBAction private func xxx() {
        try! MRAppDelegate.sharedDelegate().startSessionForExerciseType(.IndoorsCardio, start: NSDate(), id: NSUUID().UUIDString)
    }
    
}

