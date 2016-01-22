import Foundation
@testable import MuvrKit

extension MKScalarPredictor {
    
    ///
    /// Train incrementally the sequence and calculate the total error: Σ(predict - expect) ^ 2
    /// - parameter sequence: training set
    /// - parameter forExerciseId: exercise name
    /// - parameter expectedValue: expected value of the whole sequence
    ///
    func calculateError(sequence: [Double], forExerciseId id: String, expectedValue: Double) -> ([Double], Double) {
        var error: Double = 0
        var predictedSequence: [Double] = []
        (0..<sequence.count).forEach { index in
            self.trainPositional(Array(sequence[0...index]), forExerciseId: id)
            let nextPredict = self.predictScalarForExerciseId(id, n: index+1)!
            var nextExpected: Double
            if index == sequence.count - 1 {
                nextExpected = expectedValue
            } else {
                nextExpected = sequence[index+1]
            }
            error += pow(nextPredict - nextExpected, 2)
            predictedSequence.append(nextPredict)
        }
        
        return (predictedSequence, error)
    }
}