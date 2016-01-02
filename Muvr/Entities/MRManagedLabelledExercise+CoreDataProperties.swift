//
//  MRManagedLabelledExercise+CoreDataProperties.swift
//  Muvr
//
//  Created by Jan Machacek on 10/25/15.
//  Copyright © 2015 Muvr. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData
import MuvrKit

extension MRManagedLabelledExercise {

    @NSManaged var duration: Double
    @NSManaged var exerciseId: String
    @NSManaged var start: NSDate
    
    @NSManaged var cdIntensity: Double
    @NSManaged var cdRepetitions: Int32
    @NSManaged var cdWeight: Double

    @NSManaged var exerciseSession: MRManagedExerciseSession?

}
