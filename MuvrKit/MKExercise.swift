import Foundation

///
/// The common view of all exercises
///
public protocol MKExercise {
    var exerciseId: MKExerciseId { get }
    var repetitions: UInt? { get }
    var intensity: MKExerciseIntensity? { get }
    var weight: Double? { get }
}
