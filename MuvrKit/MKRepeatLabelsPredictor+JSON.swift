/// Extension to handle serialization
public extension MKRepeatLabelsPredictor {
    
    public var state: [String : AnyObject] {
        return exercises.reduce([:]) { (var dict, entry) in
            let (id, labels) = entry
            var ls: [String : AnyObject] = labels.0.reduce([:]) { (var ls, l) in
                switch l {
                case .Weight(let w): ls["weight"] = w
                case .Repetitions(let r): ls["repetitions"] = r
                case .Intensity(let i): ls["intensity"] = i
                }
                return ls
            }
            ls["duration"] = labels.1
            dict[id] = ls
            return dict
        }
    }
    
    public func restore(state: [String : AnyObject]) {
        state.forEach { id, labels in
            guard let duration = labels["duration"] as? NSTimeInterval else { return }
            var ls: [MKExerciseLabel] = []
            if let weight = labels["weight"] as? Double { ls.append(.Weight(weight: weight)) }
            if let repetitions = labels["repetitions"] as? Int { ls.append(.Repetitions(repetitions: repetitions)) }
            if let intensity = labels["intensity"] as? Double { ls.append(.Intensity(intensity: intensity)) }
            exercises[id] = (ls, duration)
        }
    }
    
    public convenience init?(fromJson json: NSData) {
        self.init()
        do { try self.restore(json) } catch { return nil }
    }
    
    
}
