import Foundation
import MuvrKit

struct MRExercise : MKExercise {
    let exerciseId: MKExerciseId
    let duration: Double
    let repetitions: Int32?
    let intensity: MKExerciseIntensity?
    let weight: Double?
    let confidence: Double
}
