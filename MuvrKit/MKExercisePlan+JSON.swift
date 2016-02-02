import Foundation

///
/// Adds JSON serialization to the exercise plan. Typical usage starts by having a complete exercise plan,
/// saving it, and the loading it, but resetting it to its initial state.
///
extension MKExercisePlan {
    
    ///
    /// Returns the JSON representation of the plan
    /// - parameter stateTransform: the function to turn ``E`` into its ``String`` representation
    /// - returns: the JSON representation
    ///
    public func json(stateTransform: E -> String) -> NSData {
        return try! NSJSONSerialization.dataWithJSONObject(metadata(stateTransform), options: [])
    }
    
    public func metadata(stateTransform: E -> String) -> [String : AnyObject] {
        var result: [String : AnyObject] = ["chain": chain.json(stateTransform)]
        if let first = first {
            result["first"] = stateTransform(first)
        }
        return result
    }
    
    ///
    /// Returns the plan at its starting point: evaluating its ``next`` property will
    /// give the starting point of the saved chain. Technically, the loaded instance is only loading the markov chain and
    /// the first encountered state, it is not loading the state chain.
    ///
    /// - parameter json: the JSON object
    /// - parameter stateTransform: the function to turn ``AnyObject`` into its ``E`` representation
    /// - returns: the loaded exercise plan.
    ///
    public static func fromJsonFirst<E>(data: NSData, stateTransform: AnyObject -> E?) -> MKExercisePlan<E>? {
        guard let json = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments),
              let metdata = json as? [String : AnyObject]
        else { return nil }
        
        return fromMetadataFirst(metdata, stateTransform: stateTransform)
    }
    
    ///
    /// Returns the plan at its starting point: evaluating its ``next`` property will
    /// give the starting point of the saved chain. Technically, the loaded instance is only loading the markov chain and
    /// the first encountered state, it is not loading the state chain.
    ///
    /// - parameter metadata: the plan metadata
    /// - parameter stateTransform: the function to turn ``AnyObject`` into its ``E`` representation
    /// - returns: the loaded exercise plan.
    ///
    public static func fromMetadataFirst<E>(metadata: [String : AnyObject], stateTransform: AnyObject -> E?) ->MKExercisePlan<E>? {
        if let chain = metadata["chain"],
            let markovChain = MKMarkovChain<E>.fromJson(chain, stateTransform: stateTransform) {
                let first = metadata["first"].flatMap(stateTransform)
                return MKExercisePlan<E>(chain: markovChain, first: first)
        }
        
        return nil
    }

}
