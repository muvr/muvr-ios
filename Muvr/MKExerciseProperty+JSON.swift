import Foundation
import MuvrKit

extension MKExerciseProperty {
    
    static let weightProgression = "weightProgression"
    static let oneRepetitionDuration = "oneRepetitionDuration"
    static let typicalDuration = "typicalDuration"

    init?(json: AnyObject) {
        guard let json = json as? [String : AnyObject],
              let type = json["type"] as? String else { return nil}
        
        if let minimum = json["minimum"] as? NSNumber,
           let step = json["step"] as? NSNumber,
           let maximum = json["maximum"] as? NSNumber?
           where type == MKExerciseProperty.weightProgression {
            self = .WeightProgression(minimum: minimum.doubleValue, step: step.doubleValue, maximum: maximum?.doubleValue)
        } else if let duration = json["duration"] as? NSNumber where type == MKExerciseProperty.typicalDuration {
            self = .TypicalDuration(duration: duration.doubleValue)
        } else if let duration = json["duration"] as? NSNumber where type == MKExerciseProperty.oneRepetitionDuration {
            self = .OneRepetitionDuration(duration: duration.doubleValue)
        } else {
            return nil
        }
    }
    
    var json: [String : AnyObject] {
        switch self {
        case .WeightProgression(let minimum, let step, let maximum):
            var result: [String : AnyObject] = ["type":MKExerciseProperty.weightProgression, "minimum":minimum, "step":step]
            if let maximum = maximum {
                result["maximum"] = maximum
            }
            return result
        case .TypicalDuration(let duration):
            return ["type":MKExerciseProperty.typicalDuration, "duration":duration]
        case .OneRepetitionDuration(let duration):
            return ["type":MKExerciseProperty.oneRepetitionDuration, "duration":duration]
        }
    }
    
}
