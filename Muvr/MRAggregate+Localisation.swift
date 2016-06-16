import Foundation

extension MRAggregate {
    
    var title: String {
        switch self {
        case .types: return "MRAggregate.types".localized()
        case .Exercises(let muscleGroup): return muscleGroup.title
        case .MuscleGroups(let type): return type.title
        }
    }
    
}
