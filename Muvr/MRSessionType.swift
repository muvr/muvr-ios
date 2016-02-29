import MuvrKit

enum MRSessionType {

    case AdHoc(exerciseType: MKExerciseType)
    case Predef(plan: MKExercisePlan)
    case UserDef(plan: MRManagedExercisePlan)
    
    var exerciseType: MKExerciseType {
        switch self {
        case .AdHoc(let exerciseType): return exerciseType
        case .Predef(let plan): return plan.exerciseType
        case .UserDef(let plan): return plan.exerciseType
        }
    }

}
