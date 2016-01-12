import Foundation
import UIKit
import MuvrKit

class MRSessionComingUpViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBAction func unwindToComingUp(unwindSegue: UIStoryboardSegue) { }
    
    private var onSelected: (MKIncompleteExercise -> Void)!
    
    func setExercises(exercises: [MKIncompleteExercise], onSelected: MKIncompleteExercise -> Void) {
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        
        self.onSelected = onSelected
        let buttonWidth = scrollView.frame.width / 3
        scrollView.contentSize = CGSizeMake(buttonWidth * CGFloat(exercises.count), scrollView.frame.height)
        
        let buttonPadding: CGFloat = 5
        for (index, exercise) in exercises.enumerate() {
            let button = MRAlternateExerciseButton(type: UIButtonType.System)
            button.frame = CGRectMake(CGFloat(index) * buttonWidth + buttonPadding, buttonPadding, buttonWidth - buttonPadding, buttonWidth - buttonPadding)
            button.setTitleColor(UIColor.darkTextColor(), forState: .Normal)
            button.addTarget(self, action: "exerciseSelected:", forControlEvents: UIControlEvents.TouchUpInside)
            button.exercise = exercise
            scrollView.addSubview(button)
        }
    }
    
    func exerciseSelected(sender: UIButton) {
        if let exercise = (sender as? MRAlternateExerciseButton)?.exercise {
            onSelected(exercise)
        }
    }

}
