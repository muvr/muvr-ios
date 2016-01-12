import Foundation

///
/// The exercise plan provides predictions about the next exercise the user is
/// likely to perform given the history of exercises. This can be used to aid 
/// labelling and classification.
///
/// A typical flow is
/// ```
/// let plan = MKExercisePlan()
/// while still-exercising {
///    plan.addExercise(completed-exercise)
///    plan.nextExercises // the expected next exercises or []
/// }
/// ```
///
public class MKExercisePlan<E : Hashable> {
    /// The chain of planned exercises that provides the predictions
    private(set) internal var chain: MKMarkovChain<E> = MKMarkovChain()
    /// The chain of states collected so far
    private(set) internal var states: MKStateChain<E> = MKStateChain()
    /// The maximum number of states to keep
    private let statesCount: Int = 16
    /// The first state, if known
    private(set) internal var first: E?
    
    ///
    /// Initializes the exercise plan.
    ///
    public init() {
        self.first = nil
    }

    ///
    /// Initializes the exercise plan using a state chain in its first state.
    ///
    internal init(chain: MKMarkovChain<E>, first: E?) {
        self.chain = chain
        self.first = first
    }
    
    ///
    /// Adds the completed exercise to the plan.
    ///
    /// - parameter exercise: the completed exercise
    ///
    public func insert(exercise: E) {
        if first == nil { first = exercise }
        
        chain.addTransition(states, next: exercise)
        states.addState(exercise)
        states.trim(statesCount)
    }

    ///
    /// Returns the list of next exercises for the current state of the plan, or [] if no
    /// exercises are known yet.
    ///
    public var next: [E] {
        if let first = first where states.count == 0 {
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
