import Foundation
@testable import Muvr
@testable import MuvrKit

class MRExerciseSessionEvaluator {
    
    struct Result {
        /// Holds the scalar labels, for a given exerciseId, descriptor, the expected value and the predicted value
        private var scalarLabels: [(MKExercise.Id, MKExerciseLabelDescriptor, Double, Double?)] = []
        /// Holds the exercise predictions: the expected vs. the predicted one
        private var exerciseIds: [(MKExercise.Id, MKExercise.Id?)] = []
        
        /// The accuracy of label predictions; values over 0.9 represents very good predictions.
        /// Value over 0.5 will result in fairly poor user experience—every other label is wrong!
        /// - returns: the accuracy 0..1
        func labelsAccuracy() -> Double {
            let mismatchedCount = scalarLabels.reduce(0) { r, x in
                let (_, _, e, p) = x
                if let p = p where abs(e - p) < 0.01 {
                    return r
                }
                return r + 1
            }
            return 1 - Double(mismatchedCount) / Double(scalarLabels.count)
        }
        
        /// The loss of labels predictions weighted for the label range. For example, ``(e, p)`` pairs
        /// ``(10, 10), (12, 10), (14, 14), (16, 16), (10, 18)``, an average square loss would be 
        /// 2^2 + 8^2 = 68; 68 / 5 = 13.6, which might not feel so bad. However, taking the average
        /// expected value (12.4), the loss is a very large portion of it; meaning that the predictions
        /// fall well outside the expected values.
        ///
        /// Similarly, we have a notion of a "stupid" result, where the value is 0.
        ///
        /// Value 0 is great; it means no mis-predictions, values up to 0.5 are usually acceptable,
        /// values over 5 will result in really poor user experience.
        ///
        /// - returns: the weighted loss of label predictions.
        ///
        func labelsWeightedLoss() -> Double {
            let stupidLossIncident: Double = 10
            
            var totalLoss: Double = 0
            var totalExpected: Double = 0
            var totalStupidLoss: Double = 0
            for (_, _, e, p) in scalarLabels where p != nil {
                totalLoss += pow(e - p!, 2)
                if p! < 0.1 { totalStupidLoss += stupidLossIncident }
                totalExpected += e
            }
            let averageExpected = totalExpected / Double(scalarLabels.count)
            let averageLoss = totalLoss / Double(scalarLabels.count)
            // let averageStupidLoss = totalStupidLoss / Double(scalarLabels.count)
            return (averageLoss / averageExpected) + totalStupidLoss
        }
        
        /// The accuracy of exercise predictions; values over 0.9 represents very good predictions.
        /// Value over 0.5 will result in fairly poor user experience—every other exercise is wrong!
        /// - returns: the accuracy 0..1, where 1 is completely accurate
        func exercisesAccuracy() -> Double {
            let mismatchedExercisesCount = exerciseIds.reduce(0) { r, e in
                if e.0 != e.1 { return r + 1 }
                return r
            }
            return 1 - Double(mismatchedExercisesCount) / Double(exerciseIds.count)
        }

        private mutating func addMismatched(expectedExerciseId expected: MKExercise.Id, predictedExerciseId predicted: MKExercise.Id?) {
            exerciseIds.append((expected, predicted))
        }
        
        private mutating func addMatched(exerciseId exerciseId: MKExercise.Id, expectedLabels: [MKExerciseLabel], predictedLabels: [MKExerciseLabel]) {
            func extractScalar(label: MKExerciseLabel) -> Double {
                switch label {
                case .Weight(let e): return e
                case .Intensity(let e): return e
                case .Repetitions(let e): return Double(e)
                }
            }
            
            for expectedLabel in expectedLabels {
                let expected = extractScalar(expectedLabel)
                let predicted = predictedLabels.filter { $0.descriptor == expectedLabel.descriptor }.first.map(extractScalar)
                scalarLabels.append((exerciseId, expectedLabel.descriptor, expected, predicted))
            }
            
            exerciseIds.append((exerciseId, exerciseId))
        }
        
    }
    
    private let loadedSession: MRLoadedSession
    
    init(loadedSession: MRLoadedSession) {
        self.loadedSession = loadedSession
    }
    
    
    func evaluate(session: MRManagedExerciseSession) -> Result {
        var result: Result = Result()
        
        for (detail, labels) in loadedSession.rows {
            let (exerciseId, _, _) = detail
            if let (predictedExerciseId, _, _) = session.exerciseDetailsComingUp.first {
                if predictedExerciseId == exerciseId {
                    let (predictedLabels, _) = session.predictExerciseLabelsForExerciseDetail(detail)
                    result.addMatched(exerciseId: exerciseId, expectedLabels: labels, predictedLabels: predictedLabels)
                } else {
                    result.addMismatched(expectedExerciseId: exerciseId, predictedExerciseId: predictedExerciseId)
                }
            } else {
                result.addMismatched(expectedExerciseId: exerciseId, predictedExerciseId: nil)
            }
            session.addExerciseDetail(detail, labels: labels, start: NSDate(), duration: 30)
        }

        return result
    }
    
    
    
}
