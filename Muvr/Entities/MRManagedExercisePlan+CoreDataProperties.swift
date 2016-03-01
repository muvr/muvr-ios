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

    /// this plan id
    @NSManaged var id: String
    /// id of the original plan (if not an ad-hoc session)
    @NSManaged var templateId: String?
    @NSManaged var name: String
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    /// the markov chain of exercise ids
    @NSManaged private var managedPlan: NSData?

}

extension MRManagedExercisePlan {
        
    override func awakeFromFetch() {
        if let data = managedPlan {
            plan = MKMarkovPredictor<MKExercise.Id>(json: data) { $0 as? MKExercise.Id }
        } else {
            plan = MKMarkovPredictor<MKExercise.Id>()
            managedPlan = plan.json { $0 }
        }
    }
    
    override func awakeFromInsert() {
        plan = MKMarkovPredictor<MKExercise.Id>()
        managedPlan = plan.json { $0 }
    }
    
    func save() {
        managedPlan = plan.json { $0 }
    }
    
    func insert(exerciseId: MKExercise.Id) {
        plan.insert(exerciseId)
    }
    
    var next: [MKExercise.Id] {
        return plan.next
    }
    
}

