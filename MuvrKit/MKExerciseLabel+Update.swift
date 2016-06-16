import Foundation

extension MKExerciseLabel {

    ///
    /// increment this exercise label's value by one step
    /// - parameter exerciseDetail: The associated exercise detail
    /// - return a new ``MKExerciseLabel`` having its value incremented by one step
    ///
    public func increment(_ exerciseDetail: MKExerciseDetail) -> MKExerciseLabel {
        return updateLabelForExerciseDetail(exerciseDetail, increment: true, label: self)
    }
    
    ///
    /// decrement this exercise label's value by one step
    /// - parameter exerciseDetail: The associated exercise detail
    /// - return a new ``MKExerciseLabel`` having its value decremented by one step
    ///
    public func decrement(_ exerciseDetail: MKExerciseDetail) -> MKExerciseLabel {
        return self.updateLabelForExerciseDetail(exerciseDetail, increment: false, label: self)
    }
    
    private func updateLabelForExerciseDetail(_ exerciseDetail: MKExerciseDetail, increment: Bool, label: MKExerciseLabel) -> MKExerciseLabel {
        let properties: [MKExerciseProperty] = exerciseDetail.properties
        switch label {
        case .intensity(var intensity):
            if increment { intensity = min(1, intensity + 0.2) } else { intensity = max(0, intensity - 0.2) }
            return .intensity(intensity: intensity)
        case .repetitions(var repetitions):
            if increment { repetitions = repetitions + 1 } else { repetitions = max(1, repetitions - 1) }
            return .repetitions(repetitions: repetitions)
        case .weight(var weight):
            for property in properties {
                if case .weightProgression(let minimum, let step, let maximum) = property {
                    if increment { weight = min(maximum ?? 999, weight + step) } else { weight = max(minimum, weight - step) }
                    return .weight(weight: weight)
                }
            }
            if increment { weight = weight + 0.5 } else { weight = weight - 0.5 }
            return .weight(weight: weight)
        }
    }
    

    
}
