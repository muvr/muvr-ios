import Foundation
import UIKit
import MuvrKit

///
/// A cell that displays a scalar value, like weight, repetitions or intensity
///
class MRSessionLabellingScalarTableViewCell : UITableViewCell {
    private var increment: (MKExerciseLabel -> MKExerciseLabel)!
    private var decrement: (MKExerciseLabel -> MKExerciseLabel)!
    private var exerciseLabel: MKExerciseLabel!
    private var scalarExerciseLabelSettable: MRScalarExerciseLabelSettable!

    func setExerciseLabel(exerciseLabel: MKExerciseLabel, increment: MKExerciseLabel -> MKExerciseLabel, decrement: MKExerciseLabel -> MKExerciseLabel) {
        let centreX = self.frame.width / 2
        let centreY = self.frame.height / 2
        let height = self.frame.height - 20
        let width  = ceil(height * 1.2)
        
        let frame = CGRect(x: centreX - width / 2, y: centreY - height / 2, width: width, height: height)
        let (view, scalarExerciseLabelSettable) = MRExerciseLabelViews.scalarViewForLabel(exerciseLabel, frame: frame)!
        addSubview(view)
        
        self.scalarExerciseLabelSettable = scalarExerciseLabelSettable
        self.exerciseLabel = exerciseLabel
        self.increment = increment
        self.decrement = decrement
    }
    
    @IBAction private func incrementTouched() {
        exerciseLabel = increment(exerciseLabel)
        try! scalarExerciseLabelSettable.setExerciseLabel(exerciseLabel)
    }
    
    @IBAction private func decrementTouched() {
        exerciseLabel = decrement(exerciseLabel)
        try! scalarExerciseLabelSettable.setExerciseLabel(exerciseLabel)
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
    func setExerciseDetail(exerciseDetail: MKExerciseDetail, predictedLabels: [MKExerciseLabel], missingLabels: [MKExerciseLabel], onLabelsUpdated: OnLabelsUpdated) {
        self.onLabelsUpdated = onLabelsUpdated
        self.exerciseDetail = exerciseDetail
        self.labels = predictedLabels + missingLabels
        tableView.reloadData()
    }
        
    /// Calls the onUpdate with the appropriate values
    private func update() {
        onLabelsUpdated([])
    }
    
    private func findProperty(predicate: MKExerciseProperty -> Bool) -> MKExerciseProperty? {
        for property in exerciseDetail.2 {
            if predicate(property) {
                return property
            }
        }
        return nil
    }

    private func incrementLabel(index: Int) -> (MKExerciseLabel -> MKExerciseLabel) {
        return { label in
            let newLabel = label.increment(self.exerciseDetail)
            self.labels[index] = newLabel
            self.onLabelsUpdated(self.labels)
            return newLabel
        }
    }
    
    private func decrementLabel(index: Int) -> (MKExerciseLabel -> MKExerciseLabel) {
        return { label in
            let newLabel = label.decrement(self.exerciseDetail)
            self.labels[index] = newLabel
            self.onLabelsUpdated(self.labels)
            return newLabel
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return labels.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("label", forIndexPath: indexPath) as! MRSessionLabellingScalarTableViewCell
        cell.setExerciseLabel(labels[indexPath.row], increment: incrementLabel(indexPath.row), decrement: decrementLabel(indexPath.row))
        return cell
    }
    
}
