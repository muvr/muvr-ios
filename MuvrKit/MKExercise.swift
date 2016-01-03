import Foundation

///
/// The common view of all exercises
///
public protocol MKExercise : MKIncompleteExercise {
    /// The duration date
    var duration: Double { get }
}
