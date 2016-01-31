import Foundation
@testable import Muvr
@testable import MuvrKit

class MRExerciseSessionEvaluator {
    
    struct Score {
        var matchedCount: Int
        var mismatchedCount: Int
        var missingCount: Int
        
        var mismatchedCost: Double
        
        private func totalCost() -> Double {
            let missingInstnaceCost: Double = 1
            let mismatchedInstanceCost: Double = 1000
            
            return mismatchedCost + Double(mismatchedCount) * mismatchedInstanceCost + Double(missingCount) * missingInstnaceCost
        }
    }
    
    struct Result {
        private var matchedExerciseLabelsScores: [MKExercise.Id : Score] = [:]
        private var mismatchedExercises: [MKExercise.Id : Int] = [:]
        private var matchedExercises: [MKExercise.Id : Int] = [:]
        
        /// The total cost of the result, where 0 is perfect match
        /// - returns: the total cost
        func totalCost() -> Double {
            let mismatchedExerciseInstanceCost: Double = 1000
            let mismatchedExerciseCost: Double = Double(mismatchedExercisesCount()) * mismatchedExerciseInstanceCost
            
            return mismatchedExerciseCost + matchedExerciseLabelsScores.values.reduce(0) { r, score in return r + score.totalCost() }
        }
        
        /// The accuracy of label predictions
        /// - returns: the accuracy 0..1
        func labelsAccuracy() -> Double {
            let totalCount = mismatchedLabelsCount() + matchedLabelsCount()
            return 1 - Double(mismatchedLabelsCount()) / Double(totalCount)
        }
        
        /// The accuracy of exercise predictions
        /// - returns: the accuracy 0..1, where 1 is completely accurate
        func exercisesAccuracy() -> Double {
            let totalCount = mismatchedExercisesCount() + matchedExercisesCount()
            return 1 - Double(mismatchedExercisesCount()) / Double(totalCount)
        }

        private func matchedLabelsCount() -> Int {
            return matchedExerciseLabelsScores.values.reduce(0) { r, s in return r + s.matchedCount }
        }
        
        private func mismatchedLabelsCount() -> Int {
            return matchedExerciseLabelsScores.values.reduce(0) { r, s in return r + s.mismatchedCount }
        }
        
        private func matchedExercisesCount() -> Int {
            return matchedExercises.values.reduce(0) { r, count in return r + count }
        }
        
        private func mismatchedExercisesCount() -> Int {
            return mismatchedExercises.values.reduce(0) { r, count in return r + count }
        }
        
        private mutating func addMismatched(exerciseId exerciseId: MKExercise.Id) {
            mismatchedExercises[exerciseId] = mismatchedExercises[exerciseId].map { $0 + 1 } ?? 1
        }
        
        private mutating func addMatched(exerciseId exerciseId: MKExercise.Id, expectedLabels: [MKExerciseLabel], predictedLabels: [MKExerciseLabel]) {
            matchedExercises[exerciseId] = matchedExercises[exerciseId].map { $0 + 1 } ?? 1
            let score = matchedExerciseLabelsScores[exerciseId] ?? Score(matchedCount: 0, mismatchedCount: 0, missingCount: 0, mismatchedCost: 0)
            matchedExerciseLabelsScores[exerciseId] = scoreLabels(score, expectedLabels: expectedLabels, predictedLabels: predictedLabels)
        }
        
        private func scoreLabels(score: Score, expectedLabels: [MKExerciseLabel], predictedLabels: [MKExerciseLabel]) -> Score {
            
            func labelCost(expected expected: MKExerciseLabel, predicted: MKExerciseLabel) -> Double {
                switch (expected, predicted) {
                case (.Weight(let e), .Weight(let p)): return pow(e - p, 2)
                case (.Intensity(let e), .Intensity(let p)): return pow(100 * e - 100 * p, 2)
                case (.Repetitions(let e), .Repetitions(let p)): return pow(Double(e - p), 2)
                default: fatalError()
                }
            }
            
            var matchedCount: Int = 0
            var mismatchedCount: Int = 0
            var missingCount: Int = 0
            var mismatchedCost: Double = 0
            
            for expectedLabel in expectedLabels {
                if let predictedLabel = (predictedLabels.filter { $0.descriptor == expectedLabel.descriptor }.first) {
                    let cost = labelCost(expected: expectedLabel, predicted: predictedLabel)
                    if cost < 0.001 {
                        matchedCount += 1
                    } else {
                        mismatchedCount += 1
                        mismatchedCost += cost
                    }
                } else {
                    missingCount += 1
                }
            }
            
            return Score(matchedCount: score.matchedCount + matchedCount,
                mismatchedCount: score.mismatchedCount + mismatchedCount,
                missingCount: score.missingCount + missingCount,
                mismatchedCost: score.mismatchedCost + mismatchedCost)
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
            if let (predictedExerciseId, _, _) = session.exerciseDetailsComingUp.first where predictedExerciseId == exerciseId {
                let (predictedLabels, _) = session.predictExerciseLabelsForExerciseDetail(detail)
                result.addMatched(exerciseId: exerciseId, expectedLabels: labels, predictedLabels: predictedLabels)
            } else {
                result.addMismatched(exerciseId: exerciseId)
            }
            session.addExerciseDetail(detail, labels: labels, start: NSDate(), duration: 30)
        }

        print(result)
        
        return result
    }
    
    
    
}
