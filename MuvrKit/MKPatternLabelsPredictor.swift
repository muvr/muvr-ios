///
/// A predictor that memorizes the pattern for each exercises
///
public class MKPatternLabelsPredictor: MKLabelsPredictor {
   
    // the number of reps by exercise
    internal var reps: [MKExercise.Id:[Int]] = [:]
    // the weights used by exercise
    internal var weights: [MKExercise.Id: [Double]] = [:]
    // the sets intensities by exercise
    internal var intensities: [MKExercise.Id: [Double]] = [:]
    // the sets durations by exercise
    internal var durations: [MKExercise.Id: [NSTimeInterval]] = [:]
    
    // the currentSet in the session by exercise
    private var currentSets: [MKExercise.Id:Int] = [:]
    
    public init() { }
    
    public func predictLabels(forExercise exerciseId: MKExercise.Id) -> MKExerciseLabelsWithDuration? {
        let currentSet = currentSets[exerciseId] ?? 0
        
        // get the duration for the currentSet (if known - otherwise get the previous duration)
        var duration = durations[exerciseId].map { $0[min(currentSet, $0.count-1)] }
        
        var labels: [MKExerciseLabel] = []
        
        let reps = self.reps[exerciseId]?.map { Double($0) }
        let (r, rd) = predictValue(reps, index: currentSet, exerciseId: exerciseId)
        if let r = r {
            labels.append(.Repetitions(repetitions: Int(r)))
            if let d = rd { duration = d }
        }
        
        let (w, wd) = predictValue(weights[exerciseId], index: currentSet, exerciseId: exerciseId)
        if let w = w {
            labels.append(.Weight(weight: w))
            if let d = wd { duration = d }
        }
        if let intensities = intensities[exerciseId] {
            // get the intensity for the currentSet (if known - otherwise get the previous intensity)
            labels.append(.Intensity(intensity: intensities[min(currentSet, intensities.count-1)]))
        }
        
        return duration.map { (labels, $0) }
    }
    
    // predict weight or reps according to some rules
    private func predictValue(sets: [Double]?, index: Int, exerciseId: MKExercise.Id) -> (Double?, NSTimeInterval?) {
        guard let sets = sets else { return (nil, nil) }

        if sets.count > index {
            // we know the value for the current set
            return (sets[index], nil)
        }
        
        if let last = sets.last, let i = sets.indexOf(last) where i + 1 < sets.count {
            // user is doing a repetition pattern e.g [1,2,3,1], so next value is 2
            return (sets[i + 1], durations[exerciseId]?[i + 1]) // return the corresponding duration
        }
        
        if sets.count > 1 {
            // more than 2 values find out the progression over the last 2 values
            let last = sets.count - 1
            var progression = sets[last] - sets[last - 1]
            if let intensity = intensities[exerciseId]?.last where intensity > 0.8 {
                // user reached max intensity do not increase value any further
                progression = min(progression, 0)
            }
            return (sets.last! + progression, nil)
        }
        
        return (sets.last, nil)
    }
    
    // upsert a value into the sets array
    private func updateLabel<T>(sets: [T]?, value: T, index: Int) -> [T] {
        var values = sets ?? []
        if index >= values.count { values.append(value) }
        else { values[index] = value }
        return values
    }
    
    public func correctLabels(forExercise exerciseId: MKExercise.Id, labels: MKExerciseLabelsWithDuration) {
        let currentSet = currentSets[exerciseId] ?? 0
        
        durations[exerciseId] = updateLabel(durations[exerciseId], value: labels.1, index: currentSet)
        
        // TODO: consider intensity and predicted value before updating weights and reps
        // if intensity too low => increase weight
        // if max intensity and reps predicted > actual reps => was too hard (keep existing value)
        
        labels.0.forEach {
            switch $0 {
            case .Weight(let w): self.weights[exerciseId] = updateLabel(self.weights[exerciseId], value: w, index: currentSet)
            case .Repetitions(let r): self.reps[exerciseId] = updateLabel(self.reps[exerciseId], value: r, index: currentSet)
            case .Intensity(let i): self.intensities[exerciseId] = updateLabel(self.intensities[exerciseId], value: i, index: currentSet)
            }
        }
        
        currentSets[exerciseId] = currentSet + 1
    }
    
}

public extension MKPatternLabelsPredictor {

    public var state: [String : AnyObject] {
        return ["weights": weights, "reps": reps, "intensities": intensities, "durations": durations]
    }
    
    public func restore(state: [String : AnyObject]) {
        if let weights = state["weights"] as? [MKExercise.Id: [Double]] { self.weights = weights }
        if let reps = state["reps"] as? [MKExercise.Id: [Int]] { self.reps = reps }
        if let intensities = state["intensities"] as? [MKExercise.Id: [Double]] { self.intensities = intensities }
        if let durations = state["durations"] as? [MKExercise.Id: [NSTimeInterval]] { self.durations = durations }
    }
    
    public convenience init?(fromJson json: NSData) {
        self.init()
        do { try self.restore(json) } catch { return nil }
    }

}