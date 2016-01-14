import Foundation

///
/// Provides a way to look up exercise properties
///
public protocol MKExercisePropertySource {
    
    ///
    /// Finds all exercise properties for the given ``exerciseId``.
    /// - parameter exerciseId: the exercise identity
    /// - returns: the exercise, empty if none available
    ///
    func exercisePropertiesForExerciseId(exerciseId: MKExerciseId) -> [MKExerciseProperty]
    
}