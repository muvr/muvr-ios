import Foundation

///
/// Adds JSON serialization to the transition set
///
extension MKMarkovTransitionSet {
    
    ///
    /// Returns JSON representation of this instance, applying some converting function to the State
    /// - parameter stateTransform: a function that converts the generic ``State`` to its ``String`` representaion
    /// - returns: the JSON representation
    ///
    func jsonObject(stateTransform: State -> String) -> AnyObject {
        var result: [String : AnyObject] = [:]
        for (k, v) in transitionCounter {
            result[stateTransform(k)] = v
        }
        return result
    }
    
    ///
    /// Initializes MKMarkovTransitionSet instance from its JSON representation.
    /// - parameter json: the JSON object
    /// - parameter stateTransform: the function to convert each state JSON object to ``State``
    /// - returns: the transition set
    ///
    init?(jsonObject: AnyObject, stateTransform: AnyObject -> State?) {
        guard let transitions = jsonObject as? [String : AnyObject] else { return nil }
        
        var transitionCounter: [State : Int] = [:]
        for (k, v) in transitions {
            guard let v = v as? NSNumber, let s = stateTransform(k) else { return nil }
            transitionCounter[s] = v.integerValue
        }
        self.init(transitionCounter: transitionCounter)
    }
    
}

///
/// Adds JSON serialization to the state chain
///
extension MKStateChain {

    ///
    /// Returns JSON representation of this instance, applying some converting function to the State
    /// - parameter stateTransform: a function that converts the generic ``State`` to its ``String`` representaion
    /// - returns: the JSON representation
    ///
    func jsonObject(stateTransform: State -> String) -> AnyObject {
        return states.map(stateTransform)
    }
    
    ///
    /// Initializes MKStateChain instance from its JSON representation.
    /// - parameter json: the JSON object
    /// - parameter stateTransform: the function to convert each state JSON object to ``State``
    /// - returns: the state chain
    ///
    init?(jsonObject: AnyObject, stateTransform: AnyObject -> State?) {
        guard let jsonObjects = jsonObject as? [AnyObject] else { return nil }
        
        let states = jsonObjects.flatMap(stateTransform)
        
        guard states.count == jsonObjects.count else { return nil }
        
        self.init(states: states)
    }
    
}

///
/// Adds JSON serialization to the markov chain
///
extension MKMarkovChain {
    
    ///
    /// Returns JSON representation of this instance, applying some converting function to the State
    /// - parameter stateTransform: a function that converts the generic ``State`` to its ``String`` representaion
    /// - returns: the JSON representation
    ///
    func jsonObject(stateTransform: State -> String) -> AnyObject {
        return transitionMap.map { [ "stateChain": $0.jsonObject(stateTransform), "transitionSet" : $1.jsonObject(stateTransform) ] }
    }
    
    ///
    /// Initializes MKMarkovChain instance from its JSON object representation.
    /// - parameter json: the JSON object
    /// - parameter stateTransform: the function to convert each state JSON object to ``State``
    /// - returns: the chain
    ///
    init?(jsonObject: AnyObject, stateTransform: AnyObject -> State?) {
        guard let jsonObjects = jsonObject as? [[String : AnyObject]] else { return nil }
        
        var transitionMap: [MKStateChain<State> : MKMarkovTransitionSet<State>] = [:]
        for dict in jsonObjects {
            guard let sc = dict["stateChain"], let ts = dict["transitionSet"],
                let stateChain = MKStateChain<State>(jsonObject: sc, stateTransform: stateTransform),
                let transitionSet = MKMarkovTransitionSet<State>(jsonObject: ts, stateTransform: stateTransform)
            else { return nil }
            transitionMap[stateChain] = transitionSet
        }
        
        self.init(transitionMap: transitionMap)
    }
    
}
