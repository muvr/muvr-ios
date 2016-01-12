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
    func json(stateTransform: State -> String) -> AnyObject {
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
    static func fromJson<State>(json: AnyObject, stateTransform: AnyObject -> State?) -> MKMarkovTransitionSet<State>? {
        if let json = json as? [String : AnyObject] {
            var transitionCounter: [State : Int] = [:]
            for (k, v) in json {
                if let v = v as? NSNumber, let s = stateTransform(k) {
                    transitionCounter[s] = v.integerValue
                } else {
                    return nil
                }
            }
            return MKMarkovTransitionSet<State>(transitionCounter: transitionCounter)
        }
        return nil
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
    func json(stateTransform: State -> String) -> AnyObject {
        return states.map(stateTransform)
    }
    
    ///
    /// Initializes MKStateChain instance from its JSON representation.
    /// - parameter json: the JSON object
    /// - parameter stateTransform: the function to convert each state JSON object to ``State``
    /// - returns: the state chain
    ///
    static func fromJson<State>(json: AnyObject, stateTransform: AnyObject -> State?) -> MKStateChain<State>? {
        if let json = json as? [AnyObject] {
            let states = json.flatMap(stateTransform)
            if states.count != json.count { return nil }
            return MKStateChain<State>(states: states)
        }
        return nil
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
    func json(stateTransform: State -> String) -> AnyObject {
        return transitionMap.map { (stateChain: MKStateChain<State>, transitionSet: MKMarkovTransitionSet<State>) -> AnyObject in
            return [
                "stateChain": stateChain.json(stateTransform),
                "transitionSet" : transitionSet.json(stateTransform)
            ]
        }
    }
    
    ///
    /// Initializes MKMarkovChain instance from its JSON representation.
    /// - parameter json: the JSON object
    /// - parameter stateTransform: the function to convert each state JSON object to ``State``
    /// - returns: the chain
    ///
    static func fromJson<State>(json: AnyObject, stateTransform: AnyObject -> State?) -> MKMarkovChain<State>? {
        func sctsFromJson(json: AnyObject) -> (MKStateChain<State>, MKMarkovTransitionSet<State>)? {
            if let json = json as? [String : AnyObject] {
                if let transitionSet = json["transitionSet"], let stateChain = json["stateChain"] {
                    if let ts = MKMarkovTransitionSet<State>.fromJson(transitionSet, stateTransform: stateTransform),
                        let sc = MKStateChain<State>.fromJson(stateChain, stateTransform: stateTransform) {
                            return (sc, ts)
                    }
                }
            }
            
            return nil
        }
        
        if let json = json as? [AnyObject] {
            let sctss = json.flatMap(sctsFromJson)
            if sctss.count != json.count { return nil }
            var transitionMap: [MKStateChain<State> : MKMarkovTransitionSet<State>] = [:]
            for (k, v) in sctss {
                transitionMap[k] = v
            }
            return MKMarkovChain<State>(transitionMap: transitionMap)
        }
        
        return nil
    }
    
}
