import Foundation

extension MRAggregate {
    
    var title: String {
        switch self {
        case .types: return "MRAggregate.types".localized()
        case .exercises(let muscleGroup): return muscleGroup.title
        case .muscleGroups(let type): return type.title
        }
    }
    
}
