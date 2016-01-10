import UIKit
import MuvrKit

class MRSessionViewController : UIViewController {
    @IBOutlet weak var mainExerciseView: MRExerciseView!
    private var session: MRManagedExerciseSession!
    
    func setSession(session: MRManagedExerciseSession) {
        self.session = session
    }
    
    override func viewDidAppear(animated: Bool) {
        mainExerciseView.headerTitle = "Coming up".localized()
        mainExerciseView.exercise = session.exercises.first
        mainExerciseView.start(60)
    }
    
}
