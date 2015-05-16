import Foundation

extension MRExercisePlanItem {
    
    func marshal() -> [String : AnyObject] {
        if let x = rest {
            return ["kind":"rest", "value":x.marshal()]
        }
        if let x = resistanceExercise {
            return ["kind":"resistance-exercise", "value":x.marshal()]
        }
        
        return ["kind":"unknown"]
    }
    
}