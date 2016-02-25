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
        let result: [String : AnyObject] = [
            "chain": chain.jsonObject(stateTransform),
            "states": states.jsonObject(stateTransform)
        ]
        return try! NSJSONSerialization.dataWithJSONObject(result, options: [])
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
    public convenience init?(json: NSData, stateTransform: AnyObject -> E?) {
        guard let jsonObject = try? NSJSONSerialization.JSONObjectWithData(json, options: NSJSONReadingOptions.AllowFragments),
            let dict = jsonObject as? [String : AnyObject],
            let chain = dict["chain"],
            let states = dict["states"],
            let markovChain = MKMarkovChain<E>(jsonObject: chain, stateTransform: stateTransform),
            let stateChain = MKStateChain<E>(jsonObject: states, stateTransform: stateTransform)
        else { return nil }
        
        self.init(chain: markovChain, states: stateChain)
    }
    
}
