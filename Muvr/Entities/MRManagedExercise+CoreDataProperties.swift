//
//  MRManagedExercise+CoreDataProperties.swift
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

extension MRManagedExercise {

    @NSManaged var duration: Double
    @NSManaged var exerciseType: NSObject?
    @NSManaged var id: String?
    @NSManaged var offset: Double
    @NSManaged var scalarLabels: NSSet?
    @NSManaged var session: MRManagedExerciseSession?

}
