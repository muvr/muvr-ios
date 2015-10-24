import Foundation

public struct MKLabelledExercise {
    public let exerciseId: MKExerciseId
    public let start: NSDate
    public let end: NSDate
    public let repetitions: UInt?
    public let intensity: MKExerciseIntensity?
    public let weight: Double?
    
    public init(exerciseId: MKExerciseId, start: NSDate, end: NSDate,
        repetitions: UInt?, intensity: MKExerciseIntensity?, weight: Double?) {
        self.exerciseId = exerciseId
        self.start = start
        self.end = end
        self.repetitions = repetitions
        self.intensity = intensity
        self.weight = weight
    }
}
