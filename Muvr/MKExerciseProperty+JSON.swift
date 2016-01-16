import Foundation
import MuvrKit

extension MKExerciseProperty {
    
    static let weightProgression = "weightProgression"

    init?(json: AnyObject) {
        guard let json = json as? [String : AnyObject],
              let type = json["type"] as? String else { return nil}
        
        if let minimum = json["minimum"] as? NSNumber,
           let increment = json["increment"] as? NSNumber,
           let maximum = json["maximum"] as? NSNumber?
           where type == MKExerciseProperty.weightProgression {
            self = .WeightProgression(minimum: minimum.floatValue, increment: increment.floatValue, maximum: maximum?.floatValue)
        } else {
            return nil
        }
    }
    
    var json: [String : AnyObject] {
        switch self {
        case .WeightProgression(let minimum, let increment, let maximum):
            var result: [String : AnyObject] = ["type":MKExerciseProperty.weightProgression, "minimum":minimum, "increment":increment]
            if let maximum = maximum {
                result["maximum"] = maximum
            }
            return result
        }
    }
    
}
