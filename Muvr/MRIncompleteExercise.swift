import Foundation
import MuvrKit

struct MRIncompleteExercise : MKIncompleteExercise {
    let exerciseId: MKExerciseId
    let repetitions: Int32?
    let intensity: MKExerciseIntensity?
    let weight: Double?
    let confidence: Double
}
