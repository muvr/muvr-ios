//
//  MRManagedLocation+CoreDataProperties.swift
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

extension MRManagedLocation {

    @NSManaged var latitude: Double
    @NSManaged var link: String?
    @NSManaged var longitude: Double
    @NSManaged var name: String?
    @NSManaged var labels: NSSet?
    @NSManaged var sessions: MRManagedExerciseSession?

}
