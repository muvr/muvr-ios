import UIKit
import MuvrKit

class MRSessionViewController : UIViewController {
    @IBOutlet weak var mainExerciseView: MRInteractivePlayerView!

    func setSession(session: MRManagedExerciseSession) {
        
    }
    
    override func viewDidAppear(animated: Bool) {
        mainExerciseView.progress = 60
        mainExerciseView.progressFullColor = UIColor.redColor()
        mainExerciseView.start()
    }
    
}
