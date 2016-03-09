///
/// The body muscles
///
public enum MKMuscle {

    case Biceps
    case Triceps
    case Deltoid
    case Pectoralis
    case Abs
    case Obliques
    case Lats
    case Trapezius
    case ErectorSpinae
    case Quadriceps
    case Hamstrings
    case Glutes
    case Calves
    
    ///
    /// The string identity of the muscle
    ///
    var id: String {
        switch self {
        case .Biceps: return "biceps"
        case .Triceps: return "triceps"
        case .Deltoid: return "deltoid"
        case .Pectoralis: return "pectoralis"
        case .Abs: return "abs"
        case .Obliques: return "obliques"
        case .Lats: return "lats"
        case .Trapezius: return "trapezius"
        case .ErectorSpinae: return "erector-spinae"
        case .Quadriceps: return "quadriceps"
        case .Hamstrings: return "hamstrings"
        case .Glutes: return "glutes"
        case .Calves: return "calves"
        }
    }
    
    ///
    /// the muscle group (e.g. Arms, Legs, ...) the muscle belongs to
    ///
    var muscleGroup: MKMuscleGroup {
        switch self {
        case .Biceps, .Triceps: return .Arms
        case .Deltoid: return .Shoulders
        case .Pectoralis: return .Chest
        case .Abs, .Obliques: return .Core
        case .Lats, .Trapezius, .ErectorSpinae: return .Back
        case .Quadriceps, .Hamstrings, .Glutes, .Calves: return .Legs
        }
    }
    
    ///
    /// Initializes this enum value from the String ``id``. Viz the ``id`` property.
    /// - parameter id: the muscle identity.
    ///
    public init?(id: String) {
        switch id {
        case "biceps": self = .Biceps
        case "triceps": self = .Triceps
        case "deltoid": self = .Deltoid
        case "pectoralis": self = .Pectoralis
        case "abs": self = .Abs
        case "obliques": self = .Obliques
        case "lats": self = .Lats
        case "trapezius": self = .Trapezius
        case "erector-spinae": self = .ErectorSpinae
        case "quadriceps": self = .Quadriceps
        case "hamstrings": self = .Hamstrings
        case "glutes": self = .Glutes
        case "calves": self = .Calves
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
        case .Arms: return [.Biceps, .Triceps]
        case .Back: return [.Lats, .Trapezius, .ErectorSpinae]
        case .Chest: return [.Pectoralis]
        case .Core: return [.Abs, .Obliques]
        case .Legs: return [.Glutes, .Quadriceps, .Hamstrings, .Calves]
        case .Shoulders: return [.Deltoid]
        }
    }
    
}
