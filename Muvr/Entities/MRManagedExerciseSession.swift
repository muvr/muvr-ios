//
//  MRManagedExerciseSession.swift
//  Muvr
//
//  Created by Jan Machacek on 10/25/15.
//  Copyright © 2015 Muvr. All rights reserved.
//

import Foundation
import CoreData
import MuvrKit

class MRManagedExerciseSession: NSManagedObject {

    static func insertNewObject(from session: MKExerciseSession, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExerciseSession {
        let mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedExerciseSession", inManagedObjectContext: managedObjectContext) as! MRManagedExerciseSession
        mo.id = session.id
        mo.startDate = session.startDate
        mo.exerciseModelId = session.exerciseModelId
        
        return mo
    }
    
}
