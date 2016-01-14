import Foundation
import UIKit
import MuvrKit

///
/// Displays indicators that allow the user to select the repetitions, weight and intensity
/// To use, call ``setExercise`` supplying the predicted exercise, and a function that will
/// be called when the user changes the inputs.
///
class MRSessionLabellingViewController: UIViewController {
    @IBOutlet private weak var repetitionsView: MRRepetitionsView!
    @IBOutlet private weak var weightView: MRWeightView!
    @IBOutlet private weak var intensityView: MRBarsView!
    
    /// A function that carries the new values: (repetitions, weight, intensity)
    typealias OnLabelUpdated = MKIncompleteExercise -> Void
    /// The function that will be called whenever a value changes
    private var onLabelUpdated: OnLabelUpdated!
    
    private var exercise: MKIncompleteExercise!
    
    // TODO: Configurable
    /// The default repetitions
    private let defaultRepetitions: Int32 = 10
    /// The default weight
    private let defaultWeight = 10.0
    /// The weight increment
    private let weightIncrement: Double = 1.0
    
    ///
    /// Sets the repetitions, weight and intensity from the given ``exercise``, 
    /// calling the ``onUpdate`` function whenever the user changes the given
    /// values.
    ///
    /// - parameter exercise: the exercise whose values to be displayed
    /// - parameter onUpdate: a function that will be called on change of values
    ///
    func setExercise(exercise: MKIncompleteExercise, onLabelUpdated: OnLabelUpdated) {
        self.onLabelUpdated = onLabelUpdated
        self.exercise = exercise
    }
    
    override func viewDidAppear(animated: Bool) {
        let defaultIntensity = 0.5

        repetitionsView.value = Int(exercise.repetitions ?? defaultRepetitions)
        weightView.value = exercise.weight ?? defaultWeight
        intensityView.value = Int(5 * (exercise.intensity ?? defaultIntensity))
    }

    /// Calls the onUpdate with the appropriate values
    private func update() {
        let newExercise = exercise.copy(
            repetitions: repetitionsView.value.map { Int32($0) },
            weight: weightView.value,
            intensity: Double(intensityView.value) / 5.0
        )
        onLabelUpdated(newExercise)
    }
    
    @IBAction private func startIncRepetitions() {
        repetitionsView.value = repetitionsView.value.map { $0 + 1 }
        update()
    }
    
    @IBAction private func startIncWeight() {
        weightView.value = weightView.value.map { $0 + weightIncrement }
        update()
    }
    
    @IBAction private func startIncIntensity() {
        intensityView.value = min(intensityView.value + 1, 5)
        update()
    }
    
    @IBAction private func startDecRepetitions() {
        repetitionsView.value = repetitionsView.value.map { max($0 - 1, 0) }
        update()
    }
    
    @IBAction private func startDecWeight() {
        weightView.value = weightView.value.map { max($0 - weightIncrement, 0) }
        update()
    }
    
    @IBAction private func startDecIntensity() {
        intensityView.value = max(intensityView.value - 1, 0)
        update()
    }
    
}
