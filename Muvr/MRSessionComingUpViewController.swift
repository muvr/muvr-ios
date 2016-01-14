import Foundation
import UIKit
import MuvrKit

///
/// Displays a scroll view of exercises that are coming up in the exercise session.
/// To use, call the ``setExercises`` function, providing the list of exercises to
/// be displayed, and an action to be called when an execie is selected.
///
class MRSessionComingUpViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    typealias OnSelected = MKIncompleteExercise -> Void
    private var onSelected: OnSelected!
    
    ///
    /// Compute the buttons' frames after scrollView layout
    ///
    override func viewDidLayoutSubviews() {
        let buttonWidth = scrollView.frame.width / 3
        let buttonPadding: CGFloat = 5
        scrollView.contentSize = CGSizeMake(buttonWidth * CGFloat(scrollView.subviews.count), scrollView.frame.height)
        for (index, button) in scrollView.subviews.enumerate() {
            button.frame = CGRectMake(CGFloat(index) * buttonWidth + buttonPadding, buttonPadding, buttonWidth - buttonPadding, buttonWidth - buttonPadding)
        }
    }
    
    ///
    /// Sets the exercises to be displayed, and the function to be called when an exercise is tapped
    /// - parameter exercises: the exercises to be displayed
    /// - parameter onSelected: the function to be called on selection
    ///
    func setExercises(exercises: [MKIncompleteExercise], onSelected: OnSelected) {
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        
        self.onSelected = onSelected
        
        let buttonWidth = scrollView.frame.width / 3
        scrollView.contentSize = CGSizeMake(buttonWidth * CGFloat(exercises.count), scrollView.frame.height)
        
        for exercise in exercises {
            let button = MRAlternateExerciseButton(type: UIButtonType.System)
            button.setTitleColor(UIColor.darkTextColor(), forState: .Normal)
            button.addTarget(self, action: "exerciseSelected:", forControlEvents: UIControlEvents.TouchUpInside)
            button.exercise = exercise
            scrollView.addSubview(button)
        }
    }
    
    /// This needs to be public as a handler for the button tap event. Do not call.
    func exerciseSelected(sender: UIButton) {
        if let exercise = (sender as? MRAlternateExerciseButton)?.exercise {
            onSelected(exercise)
        }
    }
}