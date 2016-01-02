import Foundation

///
/// The result of classifying an exercise
///
public struct MKClassifiedExercise : MKExercise {
    public let confidence: Double
    public let exerciseId: MKExerciseId
    public let duration: NSTimeInterval
    public let offset: NSTimeInterval // exercise starting offset from begining of session
    public let repetitions: Int32?
    public let intensity: MKExerciseIntensity?
    public let weight: Double?
}
