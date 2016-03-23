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

///
/// The exercise plan properties stored into core data
///
extension MRManagedExercisePlan : MRManagedExerciseType {

    /// this plan id
    @NSManaged var id: String
    /// id of the original plan (for predefined plans)
    @NSManaged var templateId: String?
    /// the plan's name
    @NSManaged var name: String
    /// The exercise list may vary according to the user's location
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    /// the markov chain of exercise ids
    @NSManaged private var managedPlan: NSData?
    /// the sessions running this plan
    @NSManaged var sessions: NSSet?

}

///
/// Provides easier access to the exercises Markov predictor
/// - ``insert`` and ``next`` can be called directly on ``MRManagedExercisePlan`` instance
/// - automatically (de)serialize the exercise plan from/to JSON
///
extension MRManagedExercisePlan {
    
    ///
    /// Called by core data when instance is fetched.
    /// Unserialize and setup the MKMarkovPredictor from the stored JSON data
    ///
    override func awakeFromFetch() {
        if let data = managedPlan {
            plan = MKMarkovPredictor<MKExercise.Id>(json: data) { $0 as? MKExercise.Id }
        } else {
            plan = MKMarkovPredictor<MKExercise.Id>()
            managedPlan = plan.json { $0 }
        }
    }
    
    ///
    /// Called by core data when instance is inserted.
    /// Setup an empty MKMarkovPredictor for the exercise list
    ///
    override func awakeFromInsert() {
        plan = MKMarkovPredictor<MKExercise.Id>()
        managedPlan = plan.json { $0 }
    }
    
    ///
    /// Serializes the exercise plan into JSON in order to be saved into core data
    ///
    /// The ``NSManagedObjectContext`` needs to be saved after calling ``save()`` to persist the changes
    ///
    func save() {
        managedPlan = plan.json { $0 }
    }
    
    ///
    /// Insert a new exerciseId into the exercises plan.
    ///
    /// It doesn't update the serialised JSON data (for performance reason)
    /// ``save()`` must be called for this purpose.
    ///
    func insert(exerciseId: MKExercise.Id) {
        plan.insert(exerciseId)
    }
    
    ///
    /// The list (most likely first) of upcoming exercise ids
    ///
    var next: [MKExercise.Id] {
        return plan.next
    }
    
}

