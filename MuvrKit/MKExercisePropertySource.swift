import Foundation

///
/// Provides a way to look up exercise properties
///
public protocol MKExercisePropertySource {
    
    ///
    /// Finds all exercise details for the given ``exerciseId``.
    /// - parameter exerciseId: the exercise identity
    /// - returns: the exercise details, nil if none available
    ///
    func exerciseDetailForExerciseId(_ exerciseId: MKExercise.Id) -> MKExerciseDetail?
    
}
