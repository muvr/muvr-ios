import Foundation

///
/// Represents a "range" in the matching ``MKSensorData`` that explicitly labels
/// it with the given exercise.
///
/// This is useful for training and training stages.
///
public protocol MKLabelledExercise : MKExercise {
    /// The start date
    var start: NSDate { get }
}
