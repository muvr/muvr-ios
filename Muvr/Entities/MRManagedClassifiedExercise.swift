//
//  MRManagedClassifiedExercise.swift
//  Muvr
//
//  Created by Jan Machacek on 10/25/15.
//  Copyright © 2015 Muvr. All rights reserved.
//

import Foundation
import CoreData
import MuvrKit

class MRManagedClassifiedExercise: NSManagedObject {

    static func insertNewObject(from classifiedExercise: MKClassifiedExercise, into session: MRManagedExerciseSession, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedClassifiedExercise {
        let mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedClassifiedExercise", inManagedObjectContext: managedObjectContext) as! MRManagedClassifiedExercise
        
        mo.exerciseSession = session
        
        mo.confidence = classifiedExercise.confidence
        mo.duration = classifiedExercise.duration
        mo.exerciseId = classifiedExercise.exerciseId
        mo.repetitions = classifiedExercise.repetitions
        mo.intensity = classifiedExercise.intensity
        mo.weight = classifiedExercise.weight
        
        return mo
    }

}
