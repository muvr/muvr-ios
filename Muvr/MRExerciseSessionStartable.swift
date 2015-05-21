import Foundation

protocol MRExerciseSessionStartable {
    
    func startSession(state: MRExercisingApplicationState, withPlan definition: MRResistanceExercisePlan?)
    
}
