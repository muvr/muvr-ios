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

extension MRManagedExerciseSession {

    @NSManaged var completed: Bool
    @NSManaged var end: NSTimeInterval
    @NSManaged var exerciseType: NSObject?
    @NSManaged var id: String?
    @NSManaged var sensorData: NSData?
    @NSManaged var start: NSTimeInterval
    @NSManaged var uploaded: Bool
    @NSManaged var exercises: MRManagedExercise?
    @NSManaged var location: NSSet?

}
