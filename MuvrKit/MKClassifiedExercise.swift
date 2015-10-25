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
    
    public init(confidence: Double, exerciseId: MKExerciseId, duration: NSTimeInterval, repetitions: UInt?, intensity: MKExerciseIntensity?, weight: Double?) {
        self.confidence = confidence
        self.exerciseId = exerciseId
        self.duration = duration
        self.repetitions = repetitions
        self.intensity = intensity
        self.weight = weight
    }
}
