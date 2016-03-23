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

    /// indicates if all sensor data are received
    @NSManaged var completed: Bool
    /// the session's end date
    @NSManaged var end: NSDate?
    /// the session's id
    @NSManaged var id: String?
    /// the sensor data for this session
    @NSManaged var sensorData: NSData?
    /// the session's start date
    @NSManaged var start: NSDate
    /// indicates if the session data is uploaded to cloud storage
    @NSManaged var uploaded: Bool
    /// the exercises performed in this session
    @NSManaged var exercises: NSSet
    /// the exercise plan for this session
    @NSManaged var plan: MRManagedExercisePlan
    /// the session's location
    @NSManaged var location: MRManagedLocation?

}

import MuvrKit
///
/// convenience properties
///
extension MRManagedExerciseSession {

    var exerciseType: MKExerciseType {
        return plan.exerciseType
    }
    
    var name: String {
        return plan.name
    }
    
}
