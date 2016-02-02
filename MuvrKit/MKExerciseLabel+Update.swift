import Foundation

extension MKExerciseLabel {

    public func increment(exerciseDetail: MKExerciseDetail) -> MKExerciseLabel {
        return updateLabelForExerciseDetail(exerciseDetail, increment: true, label: self)
    }
    
    public func decrement(exerciseDetail: MKExerciseDetail) -> MKExerciseLabel {
        return self.updateLabelForExerciseDetail(exerciseDetail, increment: true, label: self)
    }
    
    private func updateLabelForExerciseDetail(exerciseDetail: MKExerciseDetail, increment: Bool, label: MKExerciseLabel) -> MKExerciseLabel {
        let properties: [MKExerciseProperty] = exerciseDetail.2
        
        switch label {
        case .Intensity(var intensity):
            if increment { intensity = min(1, intensity + 0.2) } else { intensity = max(0, intensity - 0.2) }
            return .Intensity(intensity: intensity)
        case .Repetitions(var repetitions):
            if increment { repetitions = repetitions + 1 } else { repetitions = max(1, repetitions - 1) }
            return .Repetitions(repetitions: repetitions)
        case .Weight(var weight):
            for property in properties {
                if case .WeightProgression(let minimum, let step, let maximum) = property {
                    if increment { weight = min(maximum ?? 999, weight + step) } else { weight = max(minimum, weight - step) }
                    return .Weight(weight: weight)
                }
            }
            if increment { weight = weight + 0.5 } else { weight = weight - 0.5 }
            return .Weight(weight: weight)
        }
    }
    

    
}
