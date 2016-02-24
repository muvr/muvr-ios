import Foundation
import MuvrKit

struct MRExerciseLabelViews {
    
    static func scalarViewForLabel(label: MKExerciseLabel, frame: CGRect) -> (UIView, MRScalarExerciseLabelSettable)? {
        switch label {
        case .Intensity:
            let view = MRBarsView(frame: frame)
            view.backgroundColor = UIColor.whiteColor()
            try! view.setExerciseLabel(label)
            return (view, view)
        case .Repetitions:
            let view = MRRepetitionsView(frame: frame)
            view.backgroundColor = UIColor.whiteColor()
            try! view.setExerciseLabel(label)
            return (view, view)
        case .Weight:
            let view = MRWeightView(frame: frame)
            try! view.setExerciseLabel(label)
            view.backgroundColor = UIColor.whiteColor()
            return (view, view)
        }
    }
    
    static func scalarViewForDuration(duration: NSTimeInterval, frame: CGRect) -> UIView {
        let view = MRTimeView(frame: frame)
        view.backgroundColor = UIColor.whiteColor()
        view.accessibilityLabel = "Duration".localized()
        view.accessibilityIdentifier = "Duration"
        view.value = duration
        view.accessibilityValue = String(duration)
        return view
    }
    
}

extension MRWeightView : MRScalarExerciseLabelSettable {
    
    static func supports(exerciseLabel: MKExerciseLabel) -> Bool {
        switch exerciseLabel {
        case .Weight: return true
        default: return false
        }
    }
    
    func setExerciseLabel(exerciseLabel: MKExerciseLabel) throws {
        accessibilityLabel = "Weight".localized()
        accessibilityIdentifier = "Weight"
        if !MRWeightView.supports(exerciseLabel) { throw MRScalarExerciseLabelSettableError.LabelNotSupported }
        if case .Weight(let weight) = exerciseLabel {
            value = weight
            accessibilityValue = String(weight)
        }
    }
    
}

extension MRRepetitionsView : MRScalarExerciseLabelSettable {
    
    static func supports(exerciseLabel: MKExerciseLabel) -> Bool {
        switch exerciseLabel {
        case .Repetitions: return true
        default: return false
        }
    }
    
    func setExerciseLabel(exerciseLabel: MKExerciseLabel) throws {
        accessibilityLabel = "Repetitions".localized()
        accessibilityIdentifier = "Repetitions"
        if !MRRepetitionsView.supports(exerciseLabel) { throw MRScalarExerciseLabelSettableError.LabelNotSupported }
        if case .Repetitions(let repetitions) = exerciseLabel {
            value = repetitions
            accessibilityValue = String(repetitions)
        }
    }
}

extension MRBarsView : MRScalarExerciseLabelSettable {
    
    static func supports(exerciseLabel: MKExerciseLabel) -> Bool {
        switch exerciseLabel {
        case .Intensity: return true
        default: return false
        }
    }
    
    func setExerciseLabel(exerciseLabel: MKExerciseLabel) throws {
        accessibilityLabel = "Intensity".localized()
        accessibilityIdentifier = "Intensity"
        accessibilityTraits = UIAccessibilityTraitAdjustable
        if !MRBarsView.supports(exerciseLabel) { throw MRScalarExerciseLabelSettableError.LabelNotSupported }
        if case .Intensity(let intensity) = exerciseLabel {
            value = intensity
            accessibilityValue = String(intensity)
        }
    }
    
}
