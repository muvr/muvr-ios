import MuvrKit

///
/// the session content's (exercise type and plan)
/// It indicates the 'origin' of the session (adhoc, predefined, user session)
///
enum MRSessionType {

    ///
    /// AdHoc session: "Manual" selection of the session's exercise type
    ///
    case AdHoc(exerciseType: MKExerciseType)
    ///
    /// Predefined session: User selected one of the predefined exercise plan
    ///
    case Predefined(plan: MKExercisePlan)
    ///
    /// User session: User selected one of the past sessions
    ///
    case UserDefined(plan: MRManagedExercisePlan)
    
    /// The exercise type associated to the session
    var exerciseType: MKExerciseType {
        switch self {
        case .AdHoc(let exerciseType): return exerciseType
        case .Predefined(let plan): return plan.exerciseType
        case .UserDefined(let plan): return plan.exerciseType
        }
    }
    
    /// The session's name
    var name: String {
        switch self {
        case .AdHoc(let exerciseType): return exerciseType.name;
        case .Predefined(let plan): return plan.name
        case .UserDefined(let plan): return plan.name
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
