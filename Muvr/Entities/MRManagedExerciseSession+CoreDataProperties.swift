//
//  MRManagedExerciseSession+CoreDataProperties.swift
//  Muvr
//
//  Created by Jan Machacek on 1/16/16.
//  Copyright © 2016 Muvr. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension MRManagedExerciseSession : MRManagedExerciseType {

    @NSManaged var completed: Bool
    @NSManaged var end: NSDate?
    @NSManaged var id: String?
    @NSManaged var sensorData: NSData?
    @NSManaged var start: NSDate
    @NSManaged var uploaded: Bool
    @NSManaged var name: String
    @NSManaged var exercises: NSSet
    @NSManaged var location: MRManagedLocation?

}
