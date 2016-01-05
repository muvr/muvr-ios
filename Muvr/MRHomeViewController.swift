import UIKit

class MRHomeViewController : UIViewController {

    override func viewDidAppear(animated: Bool) {
        MRManagedClassifiedExercise.summary(inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
    }
    
}
