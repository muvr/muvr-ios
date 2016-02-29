import MuvrKit

enum MRExercisePlan {

    case AdHoc(plan: MKExercisePlan)
    case Predef(plan: MKExercisePlan)
    case UserDef(plan: MKExercisePlan)
    
    var exercisePlan: MKExercisePlan {
        switch self {
        case .AdHoc(let p): return p
        case .Predef(let p): return p
        case .UserDef(let p): return p
        }
    }
}
