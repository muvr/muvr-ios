import Foundation

///
/// Adds JSON serialization to the Markov predictor. Typical usage starts by having a complete history,
/// saving it, and the loading it, but resetting it to its initial state.
///
extension MKMarkovPredictor {
    
    ///
    /// Returns the JSON object representation of the predictor
    /// - parameter stateTransform: the function to turn ``E`` into its ``String`` representation
    /// - returns: the JSON object representation
    ///
    internal func jsonObject(_ stateTransform: (E) -> String) -> AnyObject {
        return [
            "chain": chain.jsonObject(stateTransform),
            "states": states.jsonObject(stateTransform)
        ]
    }
    
    ///
    /// Returns the JSON representation of the predictor
    /// - parameter stateTransform: the function to turn ``E`` into its ``String`` representation
    /// - returns: the JSON representation
    ///
    public func json(_ stateTransform: (E) -> String) -> Data {
        return try! JSONSerialization.data(withJSONObject: jsonObject(stateTransform), options: [])
    }
    
    ///
    /// Returns the predictor initialised with all its states history
    /// - parameter json: the JSON object
    /// - parameter stateTransform: the function to turn ``AnyObject`` into its ``E`` representation
    ///
    internal convenience init?(jsonObject: AnyObject, stateTransform: (AnyObject) -> E?) {
        guard let dict = jsonObject as? [String : AnyObject],
            let chain = dict["chain"],
            let states = dict["states"],
            let markovChain = MKMarkovChain<E>(jsonObject: chain, stateTransform: stateTransform),
            let stateChain = MKStateChain<E>(jsonObject: states, stateTransform: stateTransform)
            else { return nil }
        
        self.init(chain: markovChain, states: stateChain)
    }
    
    ///
    /// Returns the predictor initialised with all its states history
    /// - parameter json: the JSON data
    /// - parameter stateTransform: the function to turn ``AnyObject`` into its ``E`` representation
    ///
    public convenience init?(json: Data, stateTransform: (AnyObject) -> E?) {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: json, options: JSONSerialization.ReadingOptions.allowFragments)
        else { return nil }
        
        self.init(jsonObject: jsonObject, stateTransform: stateTransform)
    }
    
}
