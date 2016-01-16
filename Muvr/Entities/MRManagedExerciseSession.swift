//
//  MRManagedExerciseSession.swift
//  Muvr
//
//  Created by Jan Machacek on 1/16/16.
//  Copyright © 2016 Muvr. All rights reserved.
//

import Foundation
import CoreData
import MuvrKit

class MRManagedExerciseSession: NSManagedObject {
    private var exerciseIdCounts: [MKExercise.Id : Int] = [:]
    
    var estimated: [MKExerciseWithLabels] = []
    var weightPredictor: MKScalarPredictor!
    var plan: MKExercisePlan<MKExercise.Id>!

    var exercisingHints: [MKClassificationHint]? {
        fatalError()
    }
    
    var exerciseIdsComingUp: [MRExerciseDetail] {
        return MRAppDelegate.sharedDelegate().exerciseDetailsForExerciseIds(plan.next, favouring: exerciseType)
    }
    
    ///
    /// Predicts labels for the given ``exerciseDetail``.
    /// - parameter exerciseDetail: the ED
    /// - returns: the predicted labels (may be empty)
    ///
    func predictExerciseLabelsForExerciseDetail(exerciseDetail: MRExerciseDetail) -> [MKExerciseLabel] {
        let (id, exerciseType, _) = exerciseDetail
        let n = exerciseIdCounts[id] ?? 0
        return exerciseType.labelDescriptors.flatMap {
            switch $0 {
            case .Repetitions: return nil
            case .Weight: return weightPredictor.predictScalarForExerciseId(id, n: n).map { .Weight(weight: $0) }
            case .Intensity: return nil
            }
        }
    }
    
    func beginExerciseDetail(exerciseDetail: MRExerciseDetail, labels: [MKExerciseLabel]) {
        fatalError()
    }
    
    func endExercise() {
        fatalError()
    }
    
    func addExerciseDetail(exerciseDetail: MRExerciseDetail, labels: [MKExerciseLabel], start: NSDate, duration: NSTimeInterval, inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        fatalError()
    }
    
}
