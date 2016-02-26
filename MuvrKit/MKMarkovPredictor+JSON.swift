import Foundation

///
/// Adds JSON serialization to the Markov predictor. Typical usage starts by having a complete history,
/// saving it, and the loading it, but resetting it to its initial state.
///
extension MKMarkovPredictor {
    
    ///
    /// Returns the JSON representation of the predictor
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
    /// Returns the predictor initialised with all its states history
    /// - parameter json: the JSON object
    /// - parameter stateTransform: the function to turn ``AnyObject`` into its ``E`` representation
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
