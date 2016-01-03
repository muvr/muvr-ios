import Foundation

public protocol MKIncompleteExercise {
    /// The exercise id—a classifier label, not localised
    var exerciseId: MKExerciseId { get }
    /// # repetitions; > 0
    var repetitions: Int32? { get }
    /// The intensity; (0..1.0)
    var intensity: MKExerciseIntensity? { get }
    /// The weight in kg; > 0
    var weight: Double? { get }
    /// The confidence that this is indeed the exercise the user has performed or is about to perform
    var confidence: Double { get }
}
