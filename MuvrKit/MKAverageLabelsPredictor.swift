///
/// A predictor that memorizes the pattern for each exercises
///
public class MKAverageLabelsPredictor: MKLabelsPredictor {
    
    public typealias Round = (MKExerciseLabelDescriptor, Double, MKExercise.Id) -> Double
    
    // a workout is a bunch of sets of different exercises
    private typealias Workout = [MKExercise.Id: ExerciseSets]
    // the exercise sets with their metrics (label + duration)
    private typealias ExerciseSets = [ExerciseSetMetrics]
    
    // provides functionality to handle metrics of a given set
    private struct ExerciseSetMetrics {
        
        private var metrics: [String:Double] = [:]
        
        init() {}
        
        init(labels: MKExerciseLabelsWithDuration) {
            metrics["duration"] = labels.1
            labels.0.forEach { metrics[$0.descriptor.id] = $0.value }
        }
        
        init(metrics: [String:Double]) { self.metrics = metrics }
        
        // increment a metric by a given amount
        mutating func inc(key: String, value: Double) {
            metrics[key] = (metrics[key] ?? 0) + value
        }
        
        // divide a metric by a given value
        mutating func div(key: String, value: Double) {
            guard let v = metrics[key] else { return }
            if value == 0 { metrics.removeValueForKey(key) }
            else { metrics[key] = v / value }
        }
        
        // keeps the minimum value for a metric between actual and given value
        mutating func minimum(key: String, value: Double) {
            if let v = metrics[key] { metrics[key] = min(v, value) }
            else { metrics[key] = value }
        }
        
        // get a metric value
        func get(key: String) -> Double? { return metrics[key] }
        // set a metric value
        mutating func set(key: String, value: Double) { metrics[key] = value }
        // update all metrics of this set given an update function
        mutating func update(f: (String, Double) -> Double) {
            metrics.forEach { key, value in
                self.metrics[key] = f(key, value)
            }
        }
        
        func forEach(f: (String, Double) -> Void) {
            metrics.forEach(f)
        }
        
        // convert the metrics to a ``MKExerciseLabelsWithDuration``
        var labelsWithDuration: MKExerciseLabelsWithDuration? {
            let labels: [MKExerciseLabel] = metrics.flatMap { k, v in
                switch k {
                case "weight": return .Weight(weight: v)
                case "repetitions": return .Repetitions(repetitions: Int(round(v)))
                case "intensity": return .Intensity(intensity: v)
                default: return nil
                }
            }
            return metrics["duration"].map { (labels, $0) }
        }
    }
    
    // holds the history of an exercise over several workouts
    private struct ExerciseSetsHistory {
        
        private var history: [ExerciseSets] = []
        private let maxHistorySize: Int
        
        // history data as JSON object
        var metadata: [[[String: Double]]] {
            return history.map { workout in
                return workout.map { $0.metrics }
            }
        }
        
        init(maxHistorySize: Int) { self.maxHistorySize = maxHistorySize }
        
        init(maxHistorySize: Int, history: [[[String:Double]]]) {
            self.init(maxHistorySize: maxHistorySize)
            self.history = history.map { workout in
                workout.map { ExerciseSetMetrics(metrics: $0) }
            }
        }
        
        // add a workout to the history
        mutating func addWorkout(workout: ExerciseSets) {
            history.append(workout)
            if history.count > maxHistorySize { history.removeFirst() }
        }
        
        // compute a weighted average over the past workout for a given sets
        // values further away from the average count less
        func weightedAvg(forSet index: Int) -> ExerciseSetMetrics {
            let avg = average(forSet: index) { _, _ in return 1.0 }
            let mins = minDistance(from: avg, forSet: index)
            let wAvg = average(forSet: index) { key, value in
                let d = self.distance(from: avg, key: key, value: value)
                let dmin = mins.get(key) ?? 0
                //return 1 / (1 + abs(d - dmin))
                return 1 / (1 + (d - dmin) * (d - dmin))
            }
            return wAvg
        }
        
        // compute the min distance from the given average for all the workouts in history
        private func minDistance(from avg: ExerciseSetMetrics, forSet index: Int) -> ExerciseSetMetrics {
            guard !history.isEmpty else { return ExerciseSetMetrics() }
            var mins: ExerciseSetMetrics = ExerciseSetMetrics()
            
            history.forEach { workout in
                guard workout.count > index else { return }
                workout[index].forEach { key, value in
                    let d = self.distance(from: avg, key: key, value: value)
                    mins.minimum(key, value: d)
                }
            }
            return mins
        }
        
        // compute the distance (absolute value of the difference) between a ref and a value
        private func distance(from ref: ExerciseSetMetrics, key: String, value: Double) -> Double {
            guard let refValue = ref.get(key) else { return 0.0 }
            return abs(refValue - value)
        }
        
        // compute the average for a given set over the whole history
        // - parameter coeff: a function which returns the coefficient to apply for each metric (e.g. always return 1 to compute the ``regular`` average)
        private func average(forSet index: Int, coeff: (String, Double) -> Double) -> ExerciseSetMetrics {
            var sums: ExerciseSetMetrics = ExerciseSetMetrics()
            var counts: ExerciseSetMetrics = ExerciseSetMetrics()
            
            history.forEach { workout in
                guard workout.count > index else { return }
                workout[index].forEach {
                    let c = coeff($0, $1)
                    counts.inc($0, value: c)
                    sums.inc($0, value: $1 * c)
                }
            }
            
            counts.forEach { key, count in
                sums.div(key, value: count)
            }
            
            return sums
        }
        
    }
    
    // the number of session to remember
    private let maxHistorySize: Int
    
    // the past sessions labels
    private var history: [MKExercise.Id: ExerciseSetsHistory] = [:]
    
    // the current session
    private var workout: [MKExercise.Id: ExerciseSets] = [:]
    
    // the correction is used to model the "tiredness" in the current session
    private var exerciseCorrections: [MKExercise.Id: ExerciseSetMetrics] = [:]
    private var workoutCorrection: [String: (Double, Int)] = [:]
    // the diffs are used when the expected value is 0 (actual / expected can't be computed)
    private var exerciseDiffs: [MKExercise.Id: ExerciseSetMetrics] = [:]
    private var workoutDiffs: [String: (Double, Int)] = [:]
    
    // a way to round predicted values
    private let roundLabel: Round
    
    public init(historySize: Int, round: Round) {
        self.maxHistorySize = historySize
        self.roundLabel = round
    }
    
    // return the correction (multiplication factor) to apply to the predicted value
    private func correction(forExerciseId exerciseId: MKExercise.Id, key: String) -> (Double?, Double?) {
        if let correction = exerciseCorrections[exerciseId]?.get(key) { return (correction, nil) }
        if let (correction, sets) = workoutCorrection[key] { return (correction / Double(sets), nil) }
        if let diff = exerciseDiffs[exerciseId]?.get(key) { return (nil, diff) }
        if let (diff, sets) = workoutDiffs[key] { return (nil, diff / Double(sets)) }
        return (nil, nil)
    }
    
    private func roundValue(forExerciseId exerciseId: MKExercise.Id)(key: String, value: Double) -> Double {
        guard let label = MKExerciseLabelDescriptor(id: key) else { return value }
        return self.roundLabel(label, value, exerciseId)
    }
    
    private func correctValue(forExerciseId exerciseId: MKExercise.Id)(key: String, value: Double) -> Double {
        let (correction, diff) = self.correction(forExerciseId: exerciseId, key: key)
        return correction.map { value * $0 } ?? diff.map { value + $0 } ?? value
    }
    
    // returns true if 2 sets are identical
    // sets are identical if weights and reps are the same
    private func sameAs(this: ExerciseSetMetrics)(that: ExerciseSetMetrics) -> Bool {
        let same: [Bool] = ["weight", "repetitions"].flatMap { key in
            if this.get(key) == nil && that.get(key) == nil { return nil }
            guard let v1 = this.get(key), let v2 = that.get(key) else { return false }
            return v1 == v2
        }
        return !same.isEmpty && same.reduce(true) { $0 && $1 }
    }
    
    // predict the labels for the next set of the given exercise
    public func predictLabels(forExercise exerciseId: MKExercise.Id) -> MKExerciseLabelsWithDuration? {
        let currentSet = workout[exerciseId]?.count ?? 0
        
        // try to return the average for the given set
        if var avg = history[exerciseId]?.weightedAvg(forSet: currentSet) {
            avg.update(correctValue(forExerciseId: exerciseId))
            avg.update(roundValue(forExerciseId: exerciseId))
            return avg.labelsWithDuration
        }
        
        // tries to find a similar set in the current session
        if let sets = workout[exerciseId],
           let last = sets.last,
           let i = sets.indexOf(sameAs(last)) where i + 1 < sets.count {
            return sets[i + 1].labelsWithDuration
        }
        
        // compute the progression over the past 2 sets in the current session
        if let sets = workout[exerciseId] where sets.count > 1 {
            let last = sets.count - 1
            let set1 = sets[last - 1]
            let set2 = sets[last]
            var next = ExerciseSetMetrics()
            set2.forEach { key, v2 in
                if let v1 = set1.get(key) { next.set(key, value: 2 * v2 - v1) }
                else { next.set(key, value: v2) }
                
            }
            next.update(roundValue(forExerciseId: exerciseId))
            return next.labelsWithDuration
        }
        
        // return the previous value in the current session
        return workout[exerciseId]?.last?.labelsWithDuration
    }
    
    // stores the actual labels for the given exercise
    public func correctLabels(forExercise exerciseId: MKExercise.Id, labels: MKExerciseLabelsWithDuration) {
        let metrics = ExerciseSetMetrics(labels: labels)
        
        updateCorrections(forExerciseId: exerciseId, metrics: metrics)
        
        // stores this set into the current session
        var sets = workout[exerciseId] ?? []
        sets.append(metrics)
        workout[exerciseId] = sets
    }
    
    // update the correction value by comparing the actual value with the average over the past sessions
    private func updateCorrections(forExerciseId exerciseId: MKExercise.Id, metrics: ExerciseSetMetrics) {
        let currentSet = workout[exerciseId]?.count ?? 0
        if var avg = history[exerciseId]?.weightedAvg(forSet: currentSet) {
            avg.update(roundValue(forExerciseId: exerciseId))
            avg.forEach { key, expected in
                guard let actual = metrics.get(key) else { return }
                if expected > 0 {
                    var correction = self.exerciseCorrections[exerciseId] ?? ExerciseSetMetrics()
                    correction.set(key, value: actual / expected)
                    self.exerciseCorrections[exerciseId] = correction
                
                    let (sum, count) = self.workoutCorrection[key] ?? (Double(self.maxHistorySize), self.maxHistorySize) // more stable for the first exercises
                    self.workoutCorrection[key] = (sum + actual / expected, count + 1)
                }
                
                var diff = self.exerciseCorrections[exerciseId] ?? ExerciseSetMetrics()
                diff.set(key, value: actual - expected)
                self.exerciseDiffs[exerciseId] = diff
                
                let (diffs, count) = self.workoutDiffs[key] ?? (0, 0)
                self.workoutDiffs[key] = (diffs + actual - expected, count + 1)
            }
        }
    }
    
}

// JSON implementation
public extension MKAverageLabelsPredictor {
    
    public var state: [String : AnyObject] {
        // add current workout into history
        workout.forEach { id, exerciseWorkout in
            var exerciseHistory = self.history[id] ?? ExerciseSetsHistory(maxHistorySize: maxHistorySize)
            exerciseHistory.addWorkout(exerciseWorkout)
            self.history[id] = exerciseHistory
        }
        return history.reduce([:]) { (var dict, entry) in
            let (id, hist) = entry
            dict[id] = hist.metadata
            return dict
        }
    }
    
    public func restore(state: [String : AnyObject]) {
        if let dict = state as? [MKExercise.Id: [[[String: Double]]]] {
            dict.forEach { id, history in
                self.history[id] = ExerciseSetsHistory(maxHistorySize: self.maxHistorySize, history: history)
            }
        }
    }
    
    public convenience init?(fromJson json: NSData, historySize: Int, round: Round) {
        self.init(historySize: historySize, round: round)
        do { try self.restore(json) } catch { return nil }
    }
    
}

private extension MKExerciseLabelDescriptor {
    init?(id: String) {
        switch id {
        case "weight": self = .Weight
        case "repetitions": self = .Repetitions
        case "intensity": self = .Intensity
        default: return nil
        }
    }
}