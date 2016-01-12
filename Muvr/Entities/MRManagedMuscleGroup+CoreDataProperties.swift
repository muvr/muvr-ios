//
//  MRManagedMuscleGroup+CoreDataProperties.swift
//  Muvr
//
//  Created by Jan Machacek on 11/01/2016.
//  Copyright © 2016 Muvr. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension MRManagedMuscleGroup {

    @NSManaged var value: String
    @NSManaged var exercisePlan: MRManagedExercisePlan?

}
