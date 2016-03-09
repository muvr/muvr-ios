///
/// A predictor that memorizes the pattern for each exercises
///
public class MKAverageLabelsPredictor: MKLabelsPredictor {
    
    public typealias Round = (MKExerciseLabelDescriptor, Double, MKExercise.Id) -> Double
    
    ///
    /// a workout is a bunch of sets of different exercises
    ///
    private typealias Workout = [MKExercise.Id: ExerciseSets]
    ///
    /// the exercise sets with their metrics (label + duration)
    ///
    private typealias ExerciseSets = [ExerciseSetMetrics]
    
    ///
    /// Provides functionality to handle metrics (i.e labels) of a given set
    ///
    private struct ExerciseSetMetrics {
        ///
        /// the metrics (i.e labels) of the set
        ///
        private var metrics: [String:Double] = [:]
        
        init() {}
        
        init(labels: MKExerciseLabelsWithDuration) {
            metrics["duration"] = labels.1
            for label in labels.0 {
                let key = label.descriptor.id
                switch label {
                case .Weight(let w): metrics[key] = w
                case .Repetitions(let r): metrics[key] = Double(r)
                case .Intensity(let i): metrics[key] = i
                }
            }
        }
        
        init(metrics: [String:Double]) { self.metrics = metrics }
        
        ///
        /// increment a metric by a given amount
        /// - parameter key: the name of the metric to increment
        /// - parameter value: the increment amount
        ///
        mutating func inc(key: String, value: Double) {
            metrics[key] = (metrics[key] ?? 0) + value
        }
        
        ///
        /// divide a metric by a given value
        /// - parameter key: the name of the metric to divide
        /// - parameter value: the divisor
        ///
        mutating func div(key: String, value: Double) {
            guard let v = metrics[key] else { return }
            if value == 0 { metrics.removeValueForKey(key) }
            else { metrics[key] = v / value }
        }
        
        ///
        /// keeps the minimum value for a metric between actual and given value
        /// - parameter key: the name of the metric to compare
        /// - parameter value: the value to compare with the actual value
        ///
        mutating func minimum(key: String, value: Double) {
            if let v = metrics[key] { metrics[key] = min(v, value) }
            else { metrics[key] = value }
        }
        
        ///
        /// get a metric value corresponding to the given key
        /// - parameter key: the name of the metric
        ///
        func get(key: String) -> Double? { return metrics[key] }
        ///
        /// set a metric value
        /// - parameter key: the name of the metric to store
        /// - parameter value: the value of the metric to store
        ///
        mutating func set(key: String, value: Double) { metrics[key] = value }
        ///
        /// update all metrics of this set given an update function
        /// - parameter f: the update function that take a metric name and value as input and produces a new metric value
        ///
        mutating func update(f: (String, Double) -> Double) {
            metrics.forEach { key, value in
                self.metrics[key] = f(key, value)
            }
        }
        ///
        /// apply a side-effecting function to all the metrics of this set
        /// - parameter f: the function to apply to all the metrics. It takes the metric name and value as input.
        ///
        func forEach(f: (String, Double) -> Void) {
            metrics.forEach(f)
        }
        
        ///
        /// convert the metrics to a ``MKExerciseLabelsWithDuration``
        ///
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
    
    ///
    /// Holds the history of an exercise over several workouts
    ///
    private struct ExerciseSetsHistory {
        
        /// 
        /// the history of an exercise over several workouts
        ///
        private var history: [ExerciseSets] = []
        ///
        /// the maximum number of workouts to keep in history
        ///
        private let maxHistorySize: Int
        ///
        /// history data as JSON object
        ///
        var jsonObject: [[[String: Double]]] {
            return history.map { workout in
                return workout.map { $0.metrics }
            }
        }
        ///
        /// create an instance with an empty history
        ///
        init(maxHistorySize: Int) { self.maxHistorySize = maxHistorySize }
        
        ///
        /// create an instance containing the given history
        ///
        init(maxHistorySize: Int, history: [[[String:Double]]]) {
            self.init(maxHistorySize: maxHistorySize)
            self.history = history.map { workout in
                workout.map { ExerciseSetMetrics(metrics: $0) }
            }
        }
        
        ///
        /// Add a workout to the history
        /// - parameter workout: the workout to add into the history
        ///
        mutating func addWorkout(workout: ExerciseSets) {
            history.append(workout)
            if history.count > maxHistorySize { history.removeFirst() }
        }
        
        ///
        /// Compute a weighted average over the past workouts for a given set
        /// (values further away from the average count less)
        /// - parameter forSet: the index of the set in the session
        /// - returns an ``ExerciseSetMetrics`` containing the average value of each metric
        ///
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
        
        ///
        /// Compute the min distance from the given average of a given set for all the workouts in history
        /// - parameter from: the average to consider to compute the minDistance
        /// - parameter forSet: the index of the set in the session
        /// - returns an ``ExerciseSetMetrics`` containing the min distance from the average
        ///
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
        
        ///
        /// Compute the distance (absolute value of the difference) between a ref and a value
        /// - parameter from: the ``ExerciseSetMetrics`` reference (typicallly contains the average)
        /// - parameter key: the metric name to consider to compute the distance
        /// - parameter value: the metric value to consider to compute the distance
        /// - returns the distance from the reference for the given metric
        ///
        private func distance(from ref: ExerciseSetMetrics, key: String, value: Double) -> Double {
            guard let refValue = ref.get(key) else { return 0.0 }
            return abs(refValue - value)
        }
        
        ///
        /// Compute the average for a given set over the whole history
        /// - parameter forSet: the index of the set in the session
        /// - parameter coeff: a function which returns the coefficient to apply for each metric (e.g. return 1 to compute the ``regular`` average)
        /// - returns an ``ExerciseSetMetrics`` containing the average of each exercise's metrics
        ///
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
    
    ///
    /// the number of session to remember
    ///
    private let maxHistorySize: Int
    
    ///
    /// the past sessions labels
    ///
    private var history: [MKExercise.Id: ExerciseSetsHistory] = [:]
    
    ///
    /// the current session
    ///
    private var workout: [MKExercise.Id: ExerciseSets] = [:]
    
    ///
    /// the exercise correction is used to model the "tiredness" of each exercise in the current session
    ///
    private var exerciseCorrections: [MKExercise.Id: ExerciseSetMetrics] = [:]
    ///
    /// the workout correction is used to model the "tiredness" of the current session globally (used when there is no correction for a given exercise)
    ///
    private var workoutCorrection: [String: (Double, Int)] = [:]
    ///
    /// the exercise diffs are used when the exercise's expected value is 0 (actual / expected can't be computed)
    ///
    private var exerciseDiffs: [MKExercise.Id: ExerciseSetMetrics] = [:]
    ///
    /// the workout diffs are used when there is no corrections for a given exercise and the expected value is 0 (actual / expected can't be computed)
    ///
    private var workoutDiffs: [String: (Double, Int)] = [:]
    
    ///
    /// a way to round predicted values
    ///
    private let roundLabel: Round
    
    /// 
    /// create an empty predictor instance
    /// - parameter historySize: the number of workout sessions to keep
    /// - parameter round: function to round predicted values
    ///
    public init(historySize: Int, round: Round) {
        self.maxHistorySize = historySize
        self.roundLabel = round
    }
    
    ///
    /// Returns the correction (multiplication factor or diff) to apply to the predicted value
    /// - parameter forExerciseId: the exercise id
    /// - parameter key: the metric name
    /// - returns a pair where the first element is the multiplication factor (if possible)
    ///           and the second is the difference to add to the predicted value (if no multiplication factor can be found)
    ///
    private func correction(forExerciseId exerciseId: MKExercise.Id, key: String) -> (Double?, Double?) {
        if let correction = exerciseCorrections[exerciseId]?.get(key) { return (correction, nil) }
        if let (correction, sets) = workoutCorrection[key] { return (correction / Double(sets), nil) }
        if let diff = exerciseDiffs[exerciseId]?.get(key) { return (nil, diff) }
        if let (diff, sets) = workoutDiffs[key] { return (nil, diff / Double(sets)) }
        return (nil, nil)
    }
    
    ///
    /// Round the predicted value to the nearest possible value
    /// - parameter forExerciseId: the exercise id
    /// - parameter key: the metric name
    /// - parameter value: the metric value
    /// - returns the rounded metric value
    ///
    private func roundValue(forExerciseId exerciseId: MKExercise.Id, key: String, value: Double) -> Double {
        guard let label = MKExerciseLabelDescriptor(id: key) else { return value }
        return self.roundLabel(label, value, exerciseId)
    }
    
    ///
    /// Correct the predicted value using in-session correction (tiredness, ...)
    /// - parameter forExerciseId: the exercise id
    /// - parameter key: the metric name
    /// - parameter value: the metric value
    /// - returns the corrected metric value
    ///
    private func correctValue(forExerciseId exerciseId: MKExercise.Id, key: String, value: Double) -> Double {
        let (correction, diff) = self.correction(forExerciseId: exerciseId, key: key)
        return correction.map { value * $0 } ?? diff.map { value + $0 } ?? value
    }
    
    ///
    /// Returns true if 2 sets are identical
    /// (sets are identical if weights and reps are the same)
    ///
    private func sameAs(this: ExerciseSetMetrics) -> (ExerciseSetMetrics) -> Bool {
        return { that in
            let same: [Bool] = ["weight", "repetitions"].flatMap { key in
                if this.get(key) == nil && that.get(key) == nil { return nil }
                guard let v1 = this.get(key), let v2 = that.get(key) else { return false }
                return v1 == v2
            }
            return !same.isEmpty && same.reduce(true) { $0 && $1 }
        }
    }
    
    ///
    /// Predict the labels for the next set of the given exercise
    /// - parameter exerciseId: the upcoming exercise id
    /// - returns the predicted labels for this exercise
    ///
    public func predictLabelsForExerciseId(exerciseId: MKExercise.Id) -> MKExerciseLabelsWithDuration? {
        let currentSet = workout[exerciseId]?.count ?? 0
        
        // try to return the average for the given set
        if var avg = history[exerciseId]?.weightedAvg(forSet: currentSet) {
            avg.update {
                let v = self.correctValue(forExerciseId: exerciseId, key: $0, value: $1)
                return self.roundValue(forExerciseId: exerciseId, key: $0, value: v)
            }
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
            next.update { self.roundValue(forExerciseId: exerciseId, key: $0, value: $1) }
            return next.labelsWithDuration
        }
        
        // return the previous value in the current session
        return workout[exerciseId]?.last?.labelsWithDuration
    }
    
    ///
    /// Stores the actual labels for the given exercise and compute the corrections to apply to the current session
    /// - parameter exerciseId: the exercise id of the finished exercise
    /// - parameter labels: the labels of the finished exercise
    ///
    public func correctLabelsForExerciseId(exerciseId: MKExercise.Id, labels: MKExerciseLabelsWithDuration) {
        let metrics = ExerciseSetMetrics(labels: labels)
        
        updateCorrections(forExerciseId: exerciseId, metrics: metrics)
        
        // stores this set into the current session
        var sets = workout[exerciseId] ?? []
        sets.append(metrics)
        workout[exerciseId] = sets
    }
    
    ///
    /// Update the correction values by comparing the actual value with the average over the past sessions
    /// - parameter exerciseId: the exercise id to correct
    /// - parameter metrics: the metrics of the finished exercise
    ///
    private func updateCorrections(forExerciseId exerciseId: MKExercise.Id, metrics: ExerciseSetMetrics) {
        let currentSet = workout[exerciseId]?.count ?? 0
        if var avg = history[exerciseId]?.weightedAvg(forSet: currentSet) {
            avg.update { self.roundValue(forExerciseId: exerciseId, key: $0, value: $1) }
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
    
    ///
    /// Saves the current workout into history
    ///
    private func saveCurrentWorkout() {
        workout.forEach { id, exerciseWorkout in
            var exerciseHistory = self.history[id] ?? ExerciseSetsHistory(maxHistorySize: maxHistorySize)
            exerciseHistory.addWorkout(exerciseWorkout)
            self.history[id] = exerciseHistory
        }
        workout = [:]
    }
    
}

///
/// JSON serialisation implementation
///
public extension MKAverageLabelsPredictor {
    
    ///
    /// the JSON representatioin of this predictor
    ///
    var json: NSData {
        saveCurrentWorkout()
        
        var dict: [String: AnyObject] = [:]
        history.forEach { dict[$0] = $1.jsonObject }
        
        return try! NSJSONSerialization.dataWithJSONObject(dict, options: [])
    }
    
    ///
    /// create a predictor instance from JSON data
    /// - parameter json: the JSON representation of the predictor
    /// - parameter historySize: the number of workout sessions to keep
    /// - parameter round: function to round predicted values
    ///
    public convenience init?(json: NSData, historySize: Int, round: Round) {
        guard let jsonObject = try? NSJSONSerialization.JSONObjectWithData(json, options: .AllowFragments),
              let allHistory = jsonObject as? [MKExercise.Id: [[[String: Double]]]]
        else { return nil }
        
        self.init(historySize: historySize, round: round)
        for (id, history) in allHistory {
            self.history[id] = ExerciseSetsHistory(maxHistorySize: maxHistorySize, history: history)
        }
    }
    
}