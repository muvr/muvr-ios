import Foundation

extension MRAggregate {
    
    var title: String {
        switch self {
        case .Types: return NSLocalizedString("MRAggregate.types", comment: "").localizedCapitalizedString
        case .Exercises(let muscleGroup): return muscleGroup.title
        case .MuscleGroups(let type): return type.title
        }
    }
    
}
