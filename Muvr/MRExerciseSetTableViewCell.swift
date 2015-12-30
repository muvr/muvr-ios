import UIKit

class MRExerciseSetTableViewCell : UITableViewCell {
    static let nib: UINib = UINib(nibName: "MRExerciseSetTableViewCell", bundle: nil)
    static let cellReuseIdentifier: String = "set"
    
    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var setSizeLabel: UILabel!
    
    func setSet(set: [MRManagedClassifiedExercise]) {
        assert(!set.isEmpty, "The set cannot be empty")
        set.forEach { x in assert(x.exerciseId == set.first!.exerciseId, "The set must be all same exercise ids") }
        
        exerciseLabel.text = set.first!.exerciseId
        if set.count == 1 {
            setSizeLabel.text = "1 set"
        } else {
            setSizeLabel.text = "\(set.count) sets"
        }
    }
    
}
