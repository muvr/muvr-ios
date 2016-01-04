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

    ///
    /// Copies this instance updating the given fields
    /// - parameter offsetDelta: the delta to the offset
    /// - parameter repetitions: the new repetitions
    /// - parameter intensity: the new intensity
    /// - parameter weight: the new weight
    /// - returns: the updated instance
    ///
    func copy(offsetDelta offsetDelta: NSTimeInterval, repetitions: Int32? = nil, intensity: MKExerciseIntensity? = nil, weight: Double? = nil) -> MKClassifiedExercise {
        return MKClassifiedExercise(confidence: confidence, exerciseId: exerciseId, duration: duration, offset: offset + offsetDelta, repetitions: repetitions, intensity: intensity, weight: weight)
    }
}
