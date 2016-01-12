import Foundation
import MuvrKit

/// Implements the MKIncompleteExercise
struct MRIncompleteExercise : MKIncompleteExercise {
    let exerciseId: MKExerciseId
    let repetitions: Int32?
    let intensity: MKExerciseIntensity?
    let weight: Double?
    let confidence: Double
}
