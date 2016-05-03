import Foundation
import MuvrKit

extension MRManagedFineLocation {
    
    static func exerciseIdsAtMajor(major: NSNumber, minor: NSNumber) -> [MKExercise.Id] {
        if minor.integerValue == 1 {
            return [
                "resistanceTargeted:arms/dumbbell-biceps-curl",
                "resistanceTargeted:chest/dumbbell-flyes",
                "resistanceTargeted:legs/dumbbell-calf-raise",
                "resistanceTargeted:shoulders/dumbbell-shoulder-press",
                "resistanceTargeted:shoulders/dumbbell-bench-press",
            ]
        }
        if minor.integerValue == 2 {
            return [
                "resistanceTargeted:arms/cable-triceps-pushdown",
                "resistanceTargeted:arms/cable-hammer-curl",
                "resistanceTargeted:arms/cable-biceps-curl",
                "resistanceTargeted:arms/reverse-cable-curl",
                "resistanceTargeted:arms/overhead-cable-curl",
                "resistanceTargeted:chest/cable-crossover",
                "resistanceTargeted:back/cable-row",
                "resistanceTargeted:core/cable-wood-chop",
                "resistanceTargeted:shoulders/cable-standing-row"
            ]
        }
        if minor.integerValue == 3 {
            return [
                "resistanceTargeted:core/russian-twist",
                "resistanceTargeted:core/dragonfly",
                "resistanceTargeted:core/crunches"
            ]
        }
        if minor.integerValue == 4 {
            return [
                "resistanceTargeted:legs/barbell-squat",
                "resistanceTargeted:legs/squat",
                "resistanceTargeted:legs/sumo-squat",
                "resistanceTargeted:legs/leg-press",
                "resistanceTargeted:legs/barbell-deadlift",
                "resistanceTargeted:legs/lunges"
            ]
        }
        
        return []
    }
    
}
