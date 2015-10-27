import Foundation

///
/// The result of classifying an exercise
///
public struct MKClassifiedExercise {
    public let confidence: Double
    public let exerciseId: MKExerciseId
    public let duration: NSTimeInterval
    public let repetitions: UInt?
    public let intensity: MKExerciseIntensity?
    public let weight: Double?
}
