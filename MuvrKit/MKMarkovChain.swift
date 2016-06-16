import Foundation

///
/// A simple implementation of the markov chain that holds transitions from
/// state1 -> state2, where state1 is a non-empty sequence of individual states
///
/// Imagine a session that repeats 5 times:
///
/// * biceps-curl
/// * triceps-extension
/// * lateral-raise
/// * X
///
/// It can be represented as transitions
/// 
/// * [biceps-curl] -> triceps-extension
/// * [biceps-curl, triceps-extension] -> lateral-raise, [triceps-extension] -> lateral-raise
/// * [biceps-curl, triceps-extension, lateral-raise] -> X, [triceps-extension, lateral-raise] -> X, [lateral-raise] -> X
/// ...
///
///
struct MKMarkovChain<State where State : Hashable> {
    private(set) internal var transitionMap: [MKStateChain<State> : MKMarkovTransitionSet<State>] = [:]

    ///
    /// Convenience method that adds a transition [previous] -> next
    /// - parameter previous: the prior state
    /// - parameter next: the next state
    ///
    mutating func addTransition(_ previous: State, next: State) {
        addTransition(MKStateChain(state: previous), next: next)
    }
    
    ///
    /// Adds a transition [previous] -> next
    /// - parameter previous: the prior state chain
    /// - parameter next: the next state
    ///
    mutating func addTransition(_ previous: MKStateChain<State>, next: State) {
        for p in previous.slices {
            var transitions = transitionMap[p] ?? MKMarkovTransitionSet()
            transitionMap[p] = transitions.addTransition(next)
        }
    }
    
    ///
    /// Computes probability of transition from state1 to state2
    /// - parameter state1: the from state
    /// - parameter state2: the to state
    /// - returns: the probability 0..1
    ///
    func transitionProbability(_ state1: State, state2: State) -> Double {
        return transitionProbability(MKStateChain(state: state1), state2: state2)
    }
    
    ///
    /// Computes probability of transition from slices of state1 to state2
    /// - parameter state1: the from state
    /// - parameter state2: the to state
    /// - returns: the probability 0..1
    ///
    func transitionProbability(_ state1: MKStateChain<State>, state2: State) -> Double {
        return transitionMap[state1].map { $0.probabilityFor(state2) } ?? 0
    }

    ///
    /// Computes pairs of (state, probability) of transitions from ``from`` to the next
    /// state. If favours longer slices of ``from``.
    /// - parameter from: the completed state chain
    /// - returns: non-ordered array of (state -> score)
    ///
    func transitionProbabilities(_ from: MKStateChain<State>) -> [(State, Double)] {
        let states = Array(Set(transitionMap.keys.flatMap { $0.states }))
        
        return from.slices.flatMap { fromSlice in
            return states.map { to in
                return (to, self.transitionProbability(fromSlice, state2: to) * Double(fromSlice.count))
            }
        }
    }
    
}

///
/// State chain that holds a sequence of states
///
struct MKStateChain<State where State : Hashable> : Hashable {
    private(set) internal var states: [State]
    
    ///
    /// Empty chain
    ///
    init() {
        self.states = []
    }
    
    ///
    /// Chain with a single entry
    /// - parameter state: the state
    ///
    init(state: State) {
        self.states = [state]
    }
    
    ///
    /// Chain with many states
    /// - parameter states: the states
    ///
    init(states: [State]) {
        self.states = states
    }
    
    ///
    /// Trims this chain by keeping the last ``maximumCount`` entries
    /// - parameter maximumCount: the maximum number of entries to keep
    ///
    mutating func trim(_ maximumCount: Int) {
        if states.count > maximumCount {
            states.removeSubrange(0..<states.count - maximumCount)
        }
    }
    
    ///
    /// Adds a new state
    /// - parameter state: the next state
    ///
    mutating func addState(_ state: State) {
        states.append(state)
    }
    
    ///
    /// The number of states
    ///
    var count: Int {
        return states.count
    }
    
    ///
    /// Slices of the states from the longest one to the shortest one
    ///
    var slices: [MKStateChain<State>] {
        // "a", "b", "c", "d"
        // [a, b, c, d]
        // [   b, c, d]
        // [      c, d]
        // [         d]
        return (0..<states.count).map { i in
            return MKStateChain(states: Array(self.states[i..<states.count]))
        }
    }
 
    /// the hash value
    var hashValue: Int {
        return self.states.reduce(0) { r, s in return Int.addWithOverflow(r, s.hashValue).0 }
    }
    
}

///
/// Implementation of ``Equatable`` for ``MKStateChain<S where S : Equatable>``
///
func ==<State where State : Equatable>(lhs: MKStateChain<State>, rhs: MKStateChain<State>) -> Bool {
    if lhs.states.count != rhs.states.count {
        return false
    }
    for (i, ls) in lhs.states.enumerated() {
        if rhs.states[i] != ls {
            return false
        }
    }
    return true
}

///
/// The transition set
///
struct MKMarkovTransitionSet<State where State : Hashable> {
    private(set) internal var transitionCounter: [State : Int] = [:]
    
    func countFor(_ state: State) -> Int {
        return transitionCounter[state] ?? 0
    }
    
    var totalCount: Int {
        return transitionCounter.values.reduce(0) { $0 + $1 }
    }
    
    func probabilityFor(_ state: State) -> Double {
        return Double(countFor(state)) / Double(totalCount)
    }
    
    mutating func addTransition(_ state: State) -> MKMarkovTransitionSet<State> {
        transitionCounter[state] = countFor(state) + 1
        return self
    }
    
}
