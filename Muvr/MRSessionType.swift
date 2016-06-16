import MuvrKit

///
/// the session content's (exercise type and plan)
/// It indicates the 'origin' of the session (adhoc, predefined, user session)
///
enum MRSessionType {

    ///
    /// AdHoc session: "Manual" selection of the session's exercise type
    ///
    case adHoc(exerciseType: MKExerciseType)
    ///
    /// Predefined session: User selected one of the predefined exercise plan
    ///
    case predefined(plan: MKExercisePlan)
    ///
    /// User session: User selected one of the past sessions
    ///
    case userDefined(plan: MRManagedExercisePlan)
    
    /// The exercise type associated to the session
    var exerciseType: MKExerciseType {
        switch self {
        case .adHoc(let exerciseType): return exerciseType
        case .predefined(let plan): return plan.exerciseType
        case .userDefined(let plan): return plan.exerciseType
        }
    }
    
    /// The session's name
    var name: String {
        switch self {
        case .adHoc(let exerciseType): return exerciseType.name;
        case .predefined(let plan): return plan.name
        case .userDefined(let plan): return plan.name
        }
    }

}

private extension MKExerciseType {
    
    /// name generated from the exercise type
    var name: String {
        var workoutName = self.title
        switch self {
        case .resistanceTargeted(let muscleGroups): workoutName = muscleGroups.map { $0.title }.joined(separator: ", ")
        default: break
        }
        return "%@ workout".localized(workoutName).localizedCapitalized
    }
    
}
