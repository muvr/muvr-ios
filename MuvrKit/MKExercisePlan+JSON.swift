extension MKExercisePlan {

    ///
    /// The JSON representation of this exercise plan
    ///
    public var json: NSData {
        let jsonObject = [
            "id": id,
            "name": name,
            "type": exerciseType.metadata,
            "plan": plan.jsonObject { $0 }
        ]
        return try! NSJSONSerialization.dataWithJSONObject(jsonObject, options: [])
    }
    
    ///
    /// Returns the exercise plan initialised with all its exercise history
    /// - parameter json: the JSON data
    ///
    public init?(json: NSData) {
        guard let jsonObject = try? NSJSONSerialization.JSONObjectWithData(json, options: .AllowFragments),
            let dict = jsonObject as? [String: AnyObject],
            let id = dict["id"] as? MKExercisePlan.Id,
            let name = dict["name"] as? String,
            let type = dict["type"] as? [String:AnyObject],
            let plan = dict["plan"],
            let exerciseType = MKExerciseType(metadata: type),
            let exercisePlan = MKMarkovPredictor<MKExercise.Id>(jsonObject: plan, stateTransform: { $0 as? String })
        else { return nil }
        self.init(id: id, name: name, exerciseType: exerciseType, plan: exercisePlan)
    }
    
}
