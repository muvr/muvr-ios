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
        
        private func filteredScalarLabels(ignoring ignored: [MKExerciseLabelDescriptor]) -> [(MKExerciseDetail, MKExerciseLabelDescriptor, MKExerciseLabel, MKExerciseLabel?)] {
            return scalarLabels.filter { return !ignored.contains($0.1) }
        }
        
        /// The accuracy of label predictions; values over 0.9 represents very good predictions.
        /// Value over 0.5 will result in fairly poor user experience—every other label is wrong!
        /// - returns: the accuracy 0..1
        func labelsAccuracy(ignoring ignored: [MKExerciseLabelDescriptor]) -> Double? {
            let filtered = filteredScalarLabels(ignoring: ignored)
            guard !filtered.isEmpty else { return nil }
            
            let mismatchedCount = filtered.reduce(0) { r, x in
                let (_, _, e, p) = x
                if let p = p where abs(e.scalar() - p.scalar()) < 0.01 {
                    return r
                }
                return r + 1
            }
            return 1 - Double(mismatchedCount) / Double(filtered.count)
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
        func labelsWeightedLoss(basis: LossBasis, ignoring ignored: [MKExerciseLabelDescriptor]) -> Double? {
            let stupidLossIncident: Double = 10
            let filtered = filteredScalarLabels(ignoring: ignored)
            guard !filtered.isEmpty else { return nil }
            
            func secondMax(exerciseId: MKExercise.Id) -> [MKExerciseLabelDescriptor: Double] {
                var sms: [MKExerciseLabelDescriptor : Double] = [:]
                for (k, x) in (filtered.filter { $0.0.0 == exerciseId }.groupBy { (_, d, _, _) in return d }) {
                    let sorted = x.map { $0.2.scalar() }.sort()
                    if sorted.count > 1 {
                        sms[k] = sorted[sorted.count - 2]
                    }
                }
                return sms
            }
            
            var totalLoss: Double = 0
            var totalExpected: Double = 0
            var totalStupidLoss: Double = 0
            for (detail, td, e, p) in filtered where p != nil {
                var loss: Double = 0
                switch basis {
                case .NumberOfTaps:
                    var taps: Int = 0
                    let minimum = detail.2.flatMap {
                        if case .WeightProgression(let minimum, _, _) = $0 {
                            return minimum
                        }
                        return nil
                    }.first ?? 0.0
                    var x = e
                    if x.subtract(p!).scalar() > 0 {
                        // e > p
                        while (x.subtract(p!).scalar() > minimum) {
                            taps += 1;
                            x = x.decrement(detail)
                        }
                    } else {
                        while (x.subtract(p!).scalar() < 0) { taps += 1; x = x.increment(detail) }
                    }
                    loss = Double(taps)
                case .RawValue:
                    loss = e.subtract(p!).scalar()
                }
                if loss > 0 {
                    var prefix = "    "
                    if loss > 5 {
                        prefix = "!   "
                    } else if loss > 10 {
                        prefix = "!!  "
                    } else if loss > 20 {
                        prefix = "!!! "
                    }
                    print("\(prefix) loss \(loss) at \(detail.0); \(e) vs \(p!)")
                    print("\(prefix) \(detail.2)")
                }
                
        
                totalLoss += pow(loss, 2)
                if abs(p!.scalar() - e.scalar()) > 0.1 { // if p and e are the same it's fine, otherwise check for stupid predicted value
                    if p!.scalar() < 0.1 && e.scalar() > 0.1 { totalStupidLoss += stupidLossIncident }
                    if let sm = secondMax(detail.0)[td] where p!.scalar() > 2 * sm && abs(p!.scalar() - e.scalar()) > 1 {
                        totalStupidLoss += stupidLossIncident
                    }
                }
                totalExpected += e.scalar()
            }
            let averageExpected = totalExpected / Double(filtered.count)
            let averageLoss = totalLoss / Double(filtered.count)
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
            if expected == predicted ?? "" {
                print(" ✓ Predicted \(predicted ?? "-") and was \(expected)")
            } else {
                print(" ✗ Predicted \(predicted ?? "-") but was \(expected)")
            }
            exerciseIds.append((expected, predicted))
        }
        
        private mutating func addLabel(exerciseDetail detail: MKExerciseDetail, expectedLabels: [MKExerciseLabel], predictedLabels: [MKExerciseLabel]) {
            for expectedLabel in expectedLabels {
                let predicted = predictedLabels.filter { $0.descriptor == expectedLabel.descriptor }.first
                if predicted == nil {
                    print("  ✗ Predicted nothing but was \(expectedLabel) for \(detail.0)")
                }
                if let predicted = predicted {
                    if predicted == expectedLabel { print("  ✓ Predicted \(predicted) and was \(expectedLabel) for \(detail.0)") }
                    else { print("  ✗ Predicted \(predicted) and was \(expectedLabel) for \(detail.0)") }
                }
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
