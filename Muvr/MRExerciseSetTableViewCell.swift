import UIKit
import MuvrKit

class MRExerciseSetTableViewCell : UITableViewCell {
    static let nib: UINib = UINib(nibName: "MRExerciseSetTableViewCell", bundle: nil)
    static let cellReuseIdentifier: String = "set"
    
    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var setSizeLabel: UILabel!
    @IBOutlet weak var stacksView: MRStackView!
    
    func setSet(set: [MKExercise]) {
        assert(!set.isEmpty, "The set cannot be empty")
        set.forEach { x in assert(x.exerciseId == set.first!.exerciseId, "The set must be all same exercise ids") }
        
        exerciseLabel.text = set.first!.exerciseId
        if set.count == 1 {
            setSizeLabel.text = "1 set"
        } else {
            setSizeLabel.text = "\(set.count) sets"
        }
        stacksView.empty()
        set.forEach { exercise in
            var color = UIColor.clearColor ()
            if let intensity = exercise.intensity {
                switch(intensity) {
                case 0..<0.34: color = UIColor.greenColor()
                case 0.34..<0.67: color = UIColor.orangeColor()
                default: color = UIColor.redColor()
                }
            }
            var reps = Int(exercise.repetitions ?? 0)
            if reps == 0 { reps = 10 } // TODO Remove
            self.stacksView.addStack(color: color, count: reps)
        }
    }
}


