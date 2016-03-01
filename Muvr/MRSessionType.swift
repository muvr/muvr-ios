import MuvrKit

enum MRSessionType {

    ///
    /// AdHoc session: "Manual" selection of the session's exercise type
    ///
    case AdHoc(exerciseType: MKExerciseType)
    ///
    /// Predefined session: User selected one of the predefined exercise plan
    ///
    case Predef(plan: MKExercisePlan)
    ///
    /// User session: User selected one of the past sessions
    ///
    case UserDef(plan: MRManagedExercisePlan)
    
    /// The exercise type associated to the session
    var exerciseType: MKExerciseType {
        switch self {
        case .AdHoc(let exerciseType): return exerciseType
        case .Predef(let plan): return plan.exerciseType
        case .UserDef(let plan): return plan.exerciseType
        }
    }
    
    /// The session's name
    var name: String {
        switch self {
        case .AdHoc(let exerciseType): return exerciseType.name;
        case .Predef(let plan): return plan.name
        case .UserDef(let plan): return plan.name
        }
    }

}

private extension MKExerciseType {
    
    /// name generated from the exercise type
    var name: String {
        switch self {
        case .IndoorsCardio: return "Cardio workout"
        case .ResistanceWholeBody: return "Whole body workout"
        case .ResistanceTargeted(let muscleGroups):
            let muscles = muscleGroups.map { $0.id }.joinWithSeparator(", ")
            return "\(muscles) workout"
        }
    }
    
}
