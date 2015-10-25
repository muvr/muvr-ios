import Foundation

///
/// Represents a "range" in the matching ``MKSensorData`` that explicitly labels
/// it with the given exercise.
///
/// This is useful for training and training stages.
///
public struct MKLabelledExercise {
    /// The exercise id—a classifier label, not localised
    public let exerciseId: MKExerciseId
    /// The start date
    public let start: NSDate
    /// The end date
    public let end: NSDate
    /// # repetitions; > 0
    public let repetitions: UInt?
    /// The intensity; (0..1.0)
    public let intensity: MKExerciseIntensity?
    /// The weight in kg; > 0
    public let weight: Double?
    
    ///
    /// Initialises this instance by assigning the matching fields
    ///
    /// - parameter exerciseId: the exercise id—the label in the classifier, not localised
    /// - parameter start: the start timestamp (wall clock)
    /// - parameter end: the end timestamp (wall clock)
    /// - parameter repetitions: the number of repetitions, if known
    /// - parameter intensity: the intensity (0..1.0), if known
    /// - parameter weight: the weight in kg, if known
    ///
    public init(exerciseId: MKExerciseId, start: NSDate, end: NSDate, repetitions: UInt?, intensity: MKExerciseIntensity?, weight: Double?) {
        self.exerciseId = exerciseId
        self.start = start
        self.end = end
        self.repetitions = repetitions
        self.intensity = intensity
        self.weight = weight
    }
}
