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
    var estimated: [MKExerciseWithLabels] = []

    var exercisingHints: [MKClassificationHint]? {
        fatalError()
    }
    
    var exerciseIdsComingUp: [MKExercise.Id] {
        fatalError()
    }
    
    func beginExerciseId(exerciseId: MKExercise.Id, labels: [MKExerciseLabel]) {
        fatalError()
    }
    
    func endExercise() {
        fatalError()
    }
    
    func addExerciseId(exerciseId: MKExercise.Id, labels: [MKExerciseLabel], start: NSDate, duration: NSTimeInterval, inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        fatalError()
    }
    
}
