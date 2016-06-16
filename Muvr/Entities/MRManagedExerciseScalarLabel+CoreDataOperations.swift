//
//  MRMangedExerciseScalarLabel+CoreDataOperations.swift
//  Muvr
//
//  Created by Jan Machacek on 1/17/16.
//  Copyright © 2016 Muvr. All rights reserved.
//

import Foundation
import CoreData
import MuvrKit

extension MRManagedExerciseScalarLabel {
    
    static func insertNewObjectIntoExercise(_ exercise: MRManagedExercise, type: String, value: NSDecimalNumber, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExerciseScalarLabel{
        let mo = NSEntityDescription.insertNewObject(forEntityName: "MRManagedExerciseScalarLabel", into: managedObjectContext) as! MRManagedExerciseScalarLabel
        
        mo.exercise = exercise
        mo.type = type
        mo.value = value
        
        return mo
    }
}
