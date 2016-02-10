public typealias MKExerciseLabelsWithDuration = ([MKExerciseLabel], NSTimeInterval)

public protocol MKLabelsPredictor {
    
    /// dictionary containing the predictor's internal state
    /// this dictionary is used for json serialization
    var state: [String : AnyObject] { get }

    func predictLabels(forExercise exercise: MKExercise.Id) -> MKExerciseLabelsWithDuration?
    
    func correctLabels(forExercise exerciseId: MKExercise.Id, labels: MKExerciseLabelsWithDuration)
    
    func restore(state: [String:AnyObject])
    
}

public extension MKLabelsPredictor {

    var json: NSData {
        return (try? NSJSONSerialization.dataWithJSONObject(state, options: [])) ?? NSData()
    }
    
    func restore(json: NSData) throws {
        let dict = try! NSJSONSerialization.JSONObjectWithData(json, options: NSJSONReadingOptions.AllowFragments)
        let state = dict as! [String : AnyObject]
        self.restore(state)
    }
    
}