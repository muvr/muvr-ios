import Foundation

///
/// The Markov predictor provides predictions about the next state that is
/// most likely to occur given the history of previoius states.
/// This can be used to aid labelling and classification.
///
/// A typical flow is
/// ```
/// let plan = MKMarkovPredictor()
/// while still-exercising {
///    plan.insert(completed-exercise)
///    plan.next // the expected next exercises or []
/// }
/// ```
///
public class MKMarkovPredictor<E : Hashable> {
    /// The chain of planned states that provides the predictions
    private(set) internal var chain: MKMarkovChain<E> = MKMarkovChain()
    /// The chain of states collected so far
    private(set) internal var states: MKStateChain<E> = MKStateChain()
    /// The maximum number of states to keep
    private let statesCount: Int = 16
    
    ///
    /// Initializes the predictor.
    ///
    public init() { }

    ///
    /// Initializes the predictor using a state chain in its first state.
    ///
    internal init(chain: MKMarkovChain<E>, states: MKStateChain<E>) {
        self.chain = chain
        self.states = states
    }
    
    ///
    /// Adds the states to the predictor's history.
    ///
    /// - parameter state: the state to add
    ///
    public func insert(state: E) {
        chain.addTransition(states, next: state)
        states.addState(state)
        states.trim(statesCount)
    }

    ///
    /// Returns the list of next states for the current state of the predictor, or [] if no
    /// states are known yet.
    ///
    public var next: [E] {
        if let first = states.states.first where states.count == 1 {
            return [first]
        }
        return uniq(chain.transitionProbabilities(states).sort { l, r in l.1 > r.1 }.map { $0.0 })
    }
    
    // Unique filter, keeping order
    private func uniq<S: SequenceType, E: Hashable where E == S.Generator.Element>(source: S) -> [E] {
        var seen = [E: Bool]()
        return source.filter { seen.updateValue(true, forKey: $0) == nil }
    }
    
}
