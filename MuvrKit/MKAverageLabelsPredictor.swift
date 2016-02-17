///
/// A predictor that memorizes the pattern for each exercises
///
public class MKAverageLabelsPredictor: MKLabelsPredictor {
    
    public typealias Round = (MKExerciseLabelDescriptor, Double, MKExercise.Id) -> Double
    
    typealias Session = [MKExerciseLabelsWithDuration]
    
    // holds the labels of the past sessions
    struct SessionLabels {
        
        // the labels of the past sessions
        var sessions: [Session] = []
        // the maximum number of sessions to keep
        let maxSessions: Int
        
        init(sessions: Int) {
            self.maxSessions = sessions
        }
        
        init(sessions: Int, metadata: [[[String:Double]]]) {
            self.init(sessions: sessions)
            self.sessions = metadata.map { session in
                return session.map { dict in
                    let duration = dict["duration"] ?? 0.0
                    let labels: [MKExerciseLabel] = dict.reduce([]) { (var labels, entry) in
                        let (k, v) = entry
                        switch k {
                        case "weight": labels.append(.Weight(weight: v))
                        case "repetitions": labels.append(.Repetitions(repetitions: Int(v)))
                        case "intensity": labels.append(.Intensity(intensity: v))
                        default: break
                        }
                        return labels
                    }
                    return (labels, duration)
                }
            }
        }
        
        // store labels of a new session
        mutating func addSession(session: Session) {
            sessions.append(session)
            if sessions.count > maxSessions {
                sessions.removeFirst()
            }
        }
        
        // compute the average for the given set over the past sessions
        func avg(forSet index: Int) -> MKExerciseLabelsWithDuration? {
            guard !sessions.isEmpty else { return nil }
            var labels: [MKExerciseLabelDescriptor: MKExerciseLabel] = [:]
            var duration: NSTimeInterval = 0.0
            var n = 0.0
            
            sessions.forEach { session in
                guard session.count > index else { return }
                let (ls, d) = session[index]
                n++
                duration += d
                ls.forEach {
                    let sum = labels[$0.descriptor]?.value ?? 0
                    switch $0 {
                    case .Weight(let v): labels[.Weight] = .Weight(weight: sum + v)
                    case .Repetitions(let v): labels[.Repetitions] = .Repetitions(repetitions: Int(sum) + v)
                    case .Intensity(let v): labels[.Intensity] = .Intensity(intensity: sum + v)
                    }
                }
            }
            
            let ls: [MKExerciseLabel] = labels.values.map {
                switch $0 {
                case .Weight(let v): return .Weight(weight: v / n)
                case .Repetitions(let v): return .Repetitions(repetitions: Int(Double(v) / n))
                case .Intensity(let v): return .Intensity(intensity: v / n)
                }
            }
            
            return (ls, duration / n)
        }
        
        // the past sessions as a JSON dictionary
        var metadata: [[[String:Double]]] {
            return sessions.map { session in
                return session.map { labels, duration in
                    var ls: [String:Double] = ["duration": duration]
                    labels.forEach { ls[$0.descriptor.id] = $0.value }
                    return ls
                }
            }
        }
    }
    
    // the number of session to remember
    private let sessions: Int
    
    // the past sessions labels
    internal var sessionLabels: [MKExercise.Id: SessionLabels] = [:]
    
    // the current session
    private var session: [MKExercise.Id: Session] = [:]
    
    // the correction is used to model the "tiredness" in the current session
    private var corrections: [MKExercise.Id: [MKExerciseLabelDescriptor:Double]] = [:]
    private var defaultCorrection: [MKExerciseLabelDescriptor: (Double, Int)] = [:]
    
    // a way to round predicted values
    private let round: Round
    
    public init(sessions: Int, round: Round) {
        self.sessions = sessions
        self.round = round
    }
    
    // return the correction (multipliation factor) to apply to the predicted value
    private func correction(forExerciseId exerciseId: MKExercise.Id, label: MKExerciseLabelDescriptor) -> Double {
        if let correction = corrections[exerciseId]?[label] { return correction }
        if let (correction, sets) = defaultCorrection[label] { return correction / Double(sets) }
        return 1.0
    }
    
    // round the predicted value (and apply correction, if any)
    private func roundLabel(forExerciseId exerciseId: MKExercise.Id)(label: MKExerciseLabel) -> MKExerciseLabel {
        let correction = self.correction(forExerciseId: exerciseId, label: label.descriptor)
        let rd = round(label.descriptor, label.value * correction, exerciseId)
        if correction != 1 {
            print("Correction \(correction) \(label.id) for \(exerciseId)")
        }
        switch label {
        case .Weight: return .Weight(weight: rd)
        case .Repetitions: return .Repetitions(repetitions: Int(rd))
        case .Intensity: return .Intensity(intensity: rd)
        }
    }
    
    // returns true if 2 sets are identical
    // sets are identical if weights and reps are the same
    private func sameAs(set: MKExerciseLabelsWithDuration)(other: MKExerciseLabelsWithDuration) -> Bool {
        var same: [Bool] = []
        set.0.forEach { l1 in
            other.0.forEach { l2 in
                guard l1.descriptor == l2.descriptor else { return }
                switch l1 {
                case .Weight: same.append(l1.value == l2.value)
                case .Repetitions: same.append(l1.value == l2.value)
                default: break
                }
            }
        }
        return !same.isEmpty && same.reduce(true) { $0 && $1 }
    }
    
    // predict the labels for the next set of the given exercise
    public func predictLabels(forExercise exerciseId: MKExercise.Id) -> MKExerciseLabelsWithDuration? {
        let currentSet = session[exerciseId]?.count ?? 0
        
        // try to return the average for the given set
        if let avgLabels = sessionLabels[exerciseId]?.avg(forSet: currentSet) {
            return (avgLabels.0.map(roundLabel(forExerciseId: exerciseId)), avgLabels.1)
        }
        
        // tries to find a similar set in the current session
        if let labels = session[exerciseId],
           let last = labels.last,
           let i = labels.indexOf(sameAs(last)) where i + 1 < labels.count {
            return labels[i + 1]
        }
        
        // compute the progression over the past 2 sets in the current session
        if let labels = session[exerciseId] where labels.count > 1 {
            let last = labels.count - 1
            let l1 = labels[last - 1]
            let l2 = labels[last]
            let duration = 2 * l1.1 - l1.1
            let labels: [MKExerciseLabel] = l2.0.map { last in
                let label1 = l1.0.filter { last.descriptor == $0.descriptor }.first
                guard let first = label1 else { return last }
                let diff = last.value - first.value
                switch last {
                case .Weight(let v): return .Weight(weight: round(.Weight, v + diff, exerciseId))
                case .Repetitions(let v): return .Repetitions(repetitions: Int(round(.Repetitions, diff + Double(v), exerciseId)))
                case .Intensity(let v): return .Intensity(intensity: round(.Intensity, v + diff, exerciseId))
                }
            }
            return (labels, duration)
        }
        
        // return the previous value in the current session
        return session[exerciseId]?.last
    }
    
    // stores the actual labels for the given exercise
    public func correctLabels(forExercise exerciseId: MKExercise.Id, labels: MKExerciseLabelsWithDuration) {
        // update the correction value by comparing the actual value with the average over the past sessions
        if let avg = sessionLabels[exerciseId]?.avg(forSet: session[exerciseId]?.count ?? 0) {
            avg.0.forEach { expected in
                let a = labels.0.filter { $0.descriptor == expected.descriptor }.first
                guard let actual = a where expected.value > 0 else { return }
                var cs = corrections[exerciseId] ?? [:]
                cs[expected.descriptor] = actual.value / expected.value
                corrections[exerciseId] = cs
                let (dc, ds) = defaultCorrection[expected.descriptor] ?? (Double(sessions), sessions) // more stable for the first exercises
                defaultCorrection[expected.descriptor] = (dc + actual.value / expected.value, ds + 1)
            }
        }
        // stores this set into the current session
        var sets = session[exerciseId] ?? []
        sets.append(labels)
        session[exerciseId] = sets
    }
    
}

// JSON implementation
public extension MKAverageLabelsPredictor {
    
    public var state: [String : AnyObject] {
        session.forEach { id, s in
            var sess = self.sessionLabels[id] ?? SessionLabels(sessions: sessions)
            sess.addSession(s)
            self.sessionLabels[id] = sess
        }
        return sessionLabels.reduce([:]) { (var dict, entry) in
            let (id, labels) = entry
            dict[id] = labels.metadata
            return dict
        }
    }
    
    public func restore(state: [String : AnyObject]) {
        if let dict = state as? [MKExercise.Id: [[[String: Double]]]] {
            dict.forEach { id, metadata in
                sessionLabels[id] = SessionLabels(sessions: sessions, metadata: metadata)
            }
        }
    }
    
    public convenience init?(fromJson json: NSData, sessions: Int, round: Round) {
        self.init(sessions: sessions, round: round)
        do { try self.restore(json) } catch { return nil }
    }
    
}