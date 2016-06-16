///
/// The body muscles
///
public enum MKMuscle {

    case biceps
    case triceps
    case deltoid
    case pectoralis
    case abs
    case obliques
    case lats
    case trapezius
    case erectorSpinae
    case quadriceps
    case hamstrings
    case glutes
    case calves
    
    ///
    /// The string identity of the muscle
    ///
    var id: String {
        switch self {
        case .biceps: return "biceps"
        case .triceps: return "triceps"
        case .deltoid: return "deltoid"
        case .pectoralis: return "pectoralis"
        case .abs: return "abs"
        case .obliques: return "obliques"
        case .lats: return "lats"
        case .trapezius: return "trapezius"
        case .erectorSpinae: return "erector-spinae"
        case .quadriceps: return "quadriceps"
        case .hamstrings: return "hamstrings"
        case .glutes: return "glutes"
        case .calves: return "calves"
        }
    }
    
    ///
    /// the muscle group (e.g. Arms, Legs, ...) the muscle belongs to
    ///
    var muscleGroup: MKMuscleGroup {
        switch self {
        case .biceps, .triceps: return .arms
        case .deltoid: return .shoulders
        case .pectoralis: return .chest
        case .abs, .obliques: return .core
        case .lats, .trapezius, .erectorSpinae: return .back
        case .quadriceps, .hamstrings, .glutes, .calves: return .legs
        }
    }
    
    ///
    /// Initializes this enum value from the String ``id``. Viz the ``id`` property.
    /// - parameter id: the muscle identity.
    ///
    public init?(id: String) {
        switch id {
        case "biceps": self = .biceps
        case "triceps": self = .triceps
        case "deltoid": self = .deltoid
        case "pectoralis": self = .pectoralis
        case "abs": self = .abs
        case "obliques": self = .obliques
        case "lats": self = .lats
        case "trapezius": self = .trapezius
        case "erector-spinae": self = .erectorSpinae
        case "quadriceps": self = .quadriceps
        case "hamstrings": self = .hamstrings
        case "glutes": self = .glutes
        case "calves": self = .calves
        default: return nil
        }
    }
    
}

public extension MKMuscleGroup {

    ///
    /// The list of muscles belonging to this muscle group
    ///
    var muscles: [MKMuscle] {
        switch self {
        case .arms: return [.biceps, .triceps]
        case .back: return [.lats, .trapezius, .erectorSpinae]
        case .chest: return [.pectoralis]
        case .core: return [.abs, .obliques]
        case .legs: return [.glutes, .quadriceps, .hamstrings, .calves]
        case .shoulders: return [.deltoid]
        }
    }
    
}
