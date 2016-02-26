//
//  MRManagedExercisePlan+CoreDataProperties.swift
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
import MuvrKit

extension MRManagedExercisePlan : MRManagedExerciseType {

    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged private var managedPlan: NSData

}

extension MRManagedExercisePlan {
    
    var plan: MKMarkovPredictor<MKExercise.Id> {
        get {
            return MKMarkovPredictor<MKExercise.Id>(json: managedPlan) { $0 as? MKExercise.Id }!
        }
        set {
            managedPlan = newValue.json { $0 }
        }
    }
    
}

