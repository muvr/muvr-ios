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
    var transitionMap: [MKStateChain<State> : MKMarkovTransitionSet<State>] = [:]

    ///
    /// Convenience method that adds a transition [previous] -> next
    /// - parameter previous: the prior state
    /// - parameter next: the next state
    ///
    mutating func addTransition(previous: State, next: State) {
        addTransition(MKStateChain(state: previous), next: next)
    }
    
    ///
    /// Adds a transition [previous] -> next
    /// - parameter previous: the prior state chain
    /// - parameter next: the next state
    ///
    mutating func addTransition(previous: MKStateChain<State>, next: State) {
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
    func transitionProbability(state1: State, state2: State) -> Double {
        return transitionMap[MKStateChain(state: state1)].map { $0.probabilityFor(state2) } ?? 0
    }

}

///
/// State chain that holds a sequence of states
///
struct MKStateChain<State where State : Hashable> : Hashable {
    private let states: [State]
    
    init(state: State) {
        self.states = [state]
    }
    
    init(states: [State]) {
        self.states = states
    }

    ///
    /// Slices in the array
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
 
    var hashValue: Int {
        return self.states.reduce(0) { r, s in return Int.addWithOverflow(r, s.hashValue).0 }
    }
    
}

func ==<State where State : Equatable>(lhs: MKStateChain<State>, rhs: MKStateChain<State>) -> Bool {
    if lhs.states.count != rhs.states.count {
        return false
    }
    for (i, ls) in lhs.states.enumerate() {
        if rhs.states[i] != ls {
            return false
        }
    }
    return true
}

struct MKMarkovTransitionSet<State where State : Hashable> {
    var transitionCounter: [State : Int] = [:]
    
    func countFor(state: State) -> Int {
        return transitionCounter[state] ?? 0
    }
    
    var totalCount: Int {
        return transitionCounter.values.reduce(0) { $0 + $1 }
    }
    
    func probabilityFor(state: State) -> Double {
        return Double(countFor(state)) / Double(totalCount)
    }
    
    mutating func addTransition(state: State) -> MKMarkovTransitionSet<State> {
        transitionCounter[state] = countFor(state) + 1
        return self
    }
    
}
