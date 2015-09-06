import Foundation

enum MRMode {
    case Training(resistanceExercises: [MRClassifiedResistanceExercise])
    case AssistedClassification
    case AutomaticClassification
    
    var reportMovementExercise: Bool {
        get {
            switch self {
            case .Training(_): return true
            default: return false
            }
        }
    }
    
    var exerciseReportFirst: Bool {
        get {
            switch self {
            case .Training(_): return true
            default: return false
            }
        }
    }
}
