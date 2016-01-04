import Foundation

///
/// Represents a "range" in the matching ``MKSensorData`` that explicitly labels
/// it with the given exercise.
///
/// This is useful for training and training stages.
///
public protocol MKLabelledExercise {
    /// The start date
    var start: NSDate { get }
    /// The exercise id—a classifier label, not localised
    var exerciseId: MKExerciseId { get }
    /// The end date
    var duration: Double { get }
    
    /// # repetitions; > 0
    var repetitionsLabel: Int32 { get }
    /// The intensity; (0..1.0)
    var intensityLabel: MKExerciseIntensity { get }
    /// The weight in kg; > 0
    var weightLabel: Double { get }
}
