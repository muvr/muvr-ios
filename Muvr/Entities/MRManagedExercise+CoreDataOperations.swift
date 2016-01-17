//
//  MRManagedExercise+CoreDataOperations.swift
//  Muvr
//
//  Created by Jan Machacek on 1/17/16.
//  Copyright © 2016 Muvr. All rights reserved.
//

import Foundation
import CoreData
import MuvrKit

extension MRManagedExercise {
    
    static func insertNewObjectIntoSession(session: MRManagedExerciseSession, exerciseDetail: MKExerciseDetail, labels: [MKExerciseLabel], offset: NSTimeInterval, duration: NSTimeInterval, inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        var mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedExercise", inManagedObjectContext: managedObjectContext) as! MRManagedExercise
        let (id, exerciseType, _) = exerciseDetail
        
        mo.id = id
        mo.exerciseType = exerciseType
        mo.offset = offset
        mo.duration = duration
        mo.session = session
        
        for label in labels {
            switch label {
            case .Intensity(let intensity):
                MRManagedExerciseScalarLabel.insertNewObjectIntoExercise(mo, type: label.id, value: NSDecimalNumber(double: intensity), inManagedObjectContext: managedObjectContext)
            case .Repetitions(let repetitions):
                MRManagedExerciseScalarLabel.insertNewObjectIntoExercise(mo, type: label.id, value: NSDecimalNumber(integer: repetitions), inManagedObjectContext: managedObjectContext)
            case .Weight(let weight):
                MRManagedExerciseScalarLabel.insertNewObjectIntoExercise(mo, type: label.id, value: NSDecimalNumber(double: weight), inManagedObjectContext: managedObjectContext)
            }
        }
    }

}
