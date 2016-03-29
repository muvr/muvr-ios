///
/// JSON serialisation
///
public extension MKExercisePlanItem {

    ///
    /// Convert this exercise into a JSON object
    ///
    var jsonObject: [String: AnyObject] {
        var dict: [String: AnyObject] = ["id": id]
        if let duration = duration { dict["duration"] = duration }
        if let rest = rest { dict["rest"] = rest }
        if let labels = labels where !labels.isEmpty {
            var labelDict: [String:AnyObject] = [:]
            for l in labels {
                switch l {
                case .Repetitions(let r): labelDict[l.id] = r
                case .Weight(let w): labelDict[l.id] = w
                case .Intensity(let i): labelDict[l.id] = i
                }
            }
            dict["labels"] = labelDict
        }
        return dict
    }
    
    ///
    /// Creates an exercise instance from the given JSON object
    ///
    public init?(jsonObject: AnyObject) {
        guard let dict = jsonObject as? [String: AnyObject], let id = dict["id"] as? String
            else { return nil }
        
        let duration = dict["duration"] as? NSTimeInterval
        let rest = dict["rest"] as? NSTimeInterval
        var labels: [MKExerciseLabel] = []
        
        if let labelDict = dict["labels"] as? [String:AnyObject] {
            for descriptor in labelDict.keys.flatMap({ MKExerciseLabelDescriptor(id: $0) }) {
                switch descriptor {
                case .Repetitions: if let r = labelDict[descriptor.id] as? Int { labels.append(.Repetitions(repetitions: r)) }
                case .Weight: if let w = labelDict[descriptor.id] as? Double { labels.append(.Weight(weight: w)) }
                case .Intensity: if let i = labelDict[descriptor.id] as? Double { labels.append(.Intensity(intensity: i)) }
                }
            }
        }
        
        self.init(id: id, duration: duration, rest: rest, labels: labels)
    }
    
}