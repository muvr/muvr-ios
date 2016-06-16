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
                case .repetitions(let r): labelDict[l.id] = r
                case .weight(let w): labelDict[l.id] = w
                case .intensity(let i): labelDict[l.id] = i
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
        
        let duration = dict["duration"] as? TimeInterval
        let rest = dict["rest"] as? TimeInterval
        var labels: [MKExerciseLabel] = []
        
        if let labelDict = dict["labels"] as? [String:AnyObject] {
            for descriptor in labelDict.keys.flatMap({ MKExerciseLabelDescriptor(id: $0) }) {
                switch descriptor {
                case .repetitions: if let r = labelDict[descriptor.id] as? Int { labels.append(.repetitions(repetitions: r)) }
                case .weight: if let w = labelDict[descriptor.id] as? Double { labels.append(.weight(weight: w)) }
                case .intensity: if let i = labelDict[descriptor.id] as? Double { labels.append(.intensity(intensity: i)) }
                }
            }
        }
        
        self.init(id: id, duration: duration, rest: rest, labels: labels)
    }
    
}
