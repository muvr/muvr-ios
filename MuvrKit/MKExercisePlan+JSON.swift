extension MKExercisePlan {

    ///
    /// The JSON representation of this exercise plan
    ///
    public var json: Data {
        let jsonObject = [
            "id": id,
            "name": name,
            "type": exerciseType.metadata,
            "plan": plan.jsonObject { $0 },
            "items": items.map { $0.jsonObject }
        ]
        return try! JSONSerialization.data(withJSONObject: jsonObject, options: [])
    }
    
    ///
    /// Returns the exercise plan initialised with all its exercise history
    /// - parameter json: the JSON data
    ///
    public init?(json: Data, filename: String?) {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: json, options: .allowFragments),
            let dict = jsonObject as? [String: AnyObject],
            let id = dict["id"] as? MKExercisePlan.Id,
            let name = dict["name"] as? String,
            let type = dict["type"] as? [String:AnyObject],
            let plan = dict["plan"],
            let exerciseType = MKExerciseType(metadata: type),
            let exercisePlan = MKMarkovPredictor<MKExercise.Id>(jsonObject: plan, stateTransform: { $0 as? String })
        else { return nil }
        
        let items = (dict["items"] as? [AnyObject] ?? []).flatMap { MKExercisePlanItem(jsonObject: $0) }
        
        self.init(id: id, name: name, exerciseType: exerciseType, plan: exercisePlan, items: items, filename: filename)
    }
    
    ///
    /// Returns the exercise plan initialised with all its exercise history
    /// - parameter file: the file URL
    ///
    public init?(file: URL) {
        guard let data = try? Data(contentsOf: file) else { return nil }
        let filename = file.lastPathComponent.map { $0.substring(to: $0.characters.index($0.endIndex, offsetBy: -5)) } // remove .json extension
        self.init(json: data, filename: filename)
    }
    
}
