import Foundation
@testable import Muvr
@testable import MuvrKit

extension MKExerciseLabel {

    func scalar() -> Double {
        switch self {
        case .Weight(let e): return e
        case .Intensity(let e): return e
        case .Repetitions(let e): return Double(e)
        }
    }
    
    func subtract(that: MKExerciseLabel) -> MKExerciseLabel {
        assert(self.descriptor == that.descriptor)
        
        switch (self, that) {
        case (.Weight(let l), .Weight(let r)): return .Weight(weight: l - r)
        case (.Intensity(let l), .Intensity(let r)): return .Intensity(intensity: l - r)
        case (.Repetitions(let l), .Repetitions(let r)): return .Repetitions(repetitions: l - r)
        default: fatalError("Cannot subtract \(that) from \(self)")
        }
    }
    
}

class MRExerciseSessionEvaluator {
    
    struct Result {
        /// Holds the scalar labels, for a given exerciseId, descriptor, the expected value and the predicted value
        private(set) internal var scalarLabels: [(MKExerciseDetail, MKExerciseLabelDescriptor, MKExerciseLabel, MKExerciseLabel?)] = []
        /// Holds the exercise predictions: the expected vs. the predicted one
        private(set) internal var exerciseIds: [(MKExercise.Id, MKExercise.Id?)] = []
        
        /// The accuracy of label predictions; values over 0.9 represents very good predictions.
        /// Value over 0.5 will result in fairly poor user experience—every other label is wrong!
        /// - returns: the accuracy 0..1
        func labelsAccuracy() -> Double {
            let mismatchedCount = scalarLabels.reduce(0) { r, x in
                let (_, _, e, p) = x
                if let p = p where abs(e.scalar() - p.scalar()) < 0.01 {
                    return r
                }
                return r + 1
            }
            return 1 - Double(mismatchedCount) / Double(scalarLabels.count)
        }
        
        /// The loss value basis; note that the stupid values are not affected by the basis.
        enum LossBasis {
            /// The raw value basis; loss between e = 49 and p = 56 (with step 7) is 7^2 = 49
            case RawValue
            /// The number of taps from wrong; loss between e = 49 and p = 56 (with step 7) is 1^2 = 1
            case NumberOfTaps
        }
        
        /// The loss of labels predictions weighted for the label range. For example, ``(e, p)`` pairs
        /// ``(10, 10), (12, 10), (14, 14), (16, 16), (10, 18)``, an average square loss would be 
        /// 2^2 + 8^2 = 68; 68 / 5 = 13.6, which might not feel so bad. However, taking the average
        /// expected value (12.4), the loss is a very large portion of it; meaning that the predictions
        /// fall well outside the expected values.
        ///
        /// Similarly, we have a notion of a "stupid" result, where the value is 0; or where the value
        /// is more than 100 % of the second greatest value.
        ///
        /// Value 0 is great; it means no mis-predictions, values up to 0.5 are usually acceptable,
        /// values over 5 will result in really poor user experience.
        ///
        /// - parameter basis: the loss calculation basis
        /// - returns: the weighted loss of label predictions.
        ///
        func labelsWeightedLoss(basis: LossBasis) -> Double {
            let stupidLossIncident: Double = 10
            
            var secondMaxima: [MKExerciseLabelDescriptor : Double] = [:]
            for (k, x) in (scalarLabels.groupBy { (_, d, _, _) in return d }) {
                let sorted = x.map { $0.2.scalar() }.sort()
                if sorted.count > 1 {
                    secondMaxima[k] = sorted[sorted.count - 2]
                }
            }
            
            var totalLoss: Double = 0
            var totalExpected: Double = 0
            var totalStupidLoss: Double = 0
            for (detail, td, e, p) in scalarLabels where p != nil {
                var loss: Double = 0
                switch basis {
                case .NumberOfTaps:
                    var taps: Int = 0
                    var x = e
                    if x.subtract(p!).scalar() > 0 {
                        // e > p
                        while (x.subtract(p!).scalar() > 0) { taps += 1; x = x.decrement(detail) }
                    } else {
                        while (x.subtract(p!).scalar() < 0) { taps += 1; x = x.increment(detail) }
                    }
                    loss = Double(taps)
                case .RawValue:
                    loss = e.subtract(p!).scalar()
                }
                
                totalLoss += pow(loss, 2)
                if p!.scalar() < 0.1 { totalStupidLoss += stupidLossIncident }
                if let sm = secondMaxima[td] where p!.scalar() > 2 * sm {
                    totalStupidLoss += stupidLossIncident
                }
                totalExpected += e.scalar()
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

        private mutating func addExercise(expectedExerciseId expected: MKExercise.Id, predictedExerciseId predicted: MKExercise.Id?) {
            exerciseIds.append((expected, predicted))
        }
        
        private mutating func addLabel(exerciseDetail detail: MKExerciseDetail, expectedLabels: [MKExerciseLabel], predictedLabels: [MKExerciseLabel]) {
            for expectedLabel in expectedLabels {
                let predicted = predictedLabels.filter { $0.descriptor == expectedLabel.descriptor }.first
                scalarLabels.append((detail, expectedLabel.descriptor, expectedLabel, predicted))
            }
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
                let (predictedLabels, _) = session.predictExerciseLabelsForExerciseDetail(detail)
                result.addLabel(exerciseDetail: detail, expectedLabels: labels, predictedLabels: predictedLabels)
                result.addExercise(expectedExerciseId: exerciseId, predictedExerciseId: predictedExerciseId)
            } else {
                result.addExercise(expectedExerciseId: exerciseId, predictedExerciseId: nil)
            }
            session.addExerciseDetail(detail, labels: labels, start: NSDate(), duration: 30)
        }

        return result
    }
    
    
    
}
