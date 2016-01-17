import Foundation
import UIKit
import MuvrKit

class MRSessionLabellingTableViewCell : UITableViewCell {

    func setExerciseLabel(exerciseLabel: MKExerciseLabel) {
        let centreX = self.frame.width / 2
        let centreY = self.frame.height / 2
        let height = self.frame.height - 20
        let width  = height * 1.2
        
        let frame = CGRect(x: centreX - width / 2, y: centreY - height / 2, width: width, height: height)
        let view = MRExerciseLabelViews.viewForLabel(exerciseLabel, frame: frame)!
        addSubview(view)
    }
    
    @IBAction private func incrementTouched() {
        print("+")
    }
    
    @IBAction private func decrementTouched() {
        print("-")
    }
    
}

///
/// Displays indicators that allow the user to select the repetitions, weight and intensity
/// To use, call ``setExercise`` supplying the predicted exercise, and a function that will
/// be called when the user changes the inputs.
///
class MRSessionLabellingViewController: UIViewController, UITableViewDataSource {
    @IBOutlet private weak var tableView: UITableView!
    
    /// A function that carries the new values: (repetitions, weight, intensity)
    typealias OnLabelsUpdated = [MKExerciseLabel] -> Void
    /// The function that will be called whenever a value changes
    private var onLabelsUpdated: OnLabelsUpdated!
    
    private var labels: [MKExerciseLabel] = []
    private var exerciseDetail: MKExerciseDetail!
    
    ///
    /// Sets exercise detail and the labels for the users to verify.
    ///
    /// - parameter exerciseDetail: the exercise whose values to be displayed
    /// - parameter onUpdate: a function that will be called on change of values
    ///
    func setExerciseDetail(exerciseDetail: MKExerciseDetail, labels: [MKExerciseLabel], onLabelsUpdated: OnLabelsUpdated) {
        self.onLabelsUpdated = onLabelsUpdated
        self.exerciseDetail = exerciseDetail
        self.labels = labels
        tableView.reloadData()
    }
        
    /// Calls the onUpdate with the appropriate values
    private func update() {
        onLabelsUpdated([])
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return labels.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("label", forIndexPath: indexPath) as! MRSessionLabellingTableViewCell
        cell.setExerciseLabel(labels[indexPath.row])
        return cell
    }
    
}
