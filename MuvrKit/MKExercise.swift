import Foundation

///
/// The result of classifying an exercise
///
public struct MKExercise {
    public typealias Id = String
    
    public let type: MKExerciseTypeDescriptor
    public let id: Id
    public let duration: NSTimeInterval
    public let offset: NSTimeInterval // exercise starting offset from begining of session
    
    ///
    /// Copies this instance updating the given fields
    /// - parameter offsetDelta: the delta to the offset
    /// - parameter repetitions: the new repetitions
    /// - parameter intensity: the new intensity
    /// - parameter weight: the new weight
    /// - returns: the updated instance
    ///
    func copy(offsetDelta offsetDelta: NSTimeInterval) -> MKExercise {
        return MKExercise(type: type, id: id, duration: duration, offset: offset + offsetDelta)
    }
}
