import Foundation

extension MRExercisePlanDeviation {
    
    func marshal() -> [String : AnyObject] {
        return ["planned":planned.marshal(), "actual":actual.marshal()]
    }
    
}