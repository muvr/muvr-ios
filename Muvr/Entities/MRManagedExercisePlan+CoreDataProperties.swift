//
//  MRManagedExercisePlan+CoreDataProperties.swift
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

extension MRManagedExercisePlan {

    @NSManaged var lon: Double
    @NSManaged var lat: Double
    @NSManaged var exerciseType: Int32
    @NSManaged var muscleGroups: NSSet?

}
