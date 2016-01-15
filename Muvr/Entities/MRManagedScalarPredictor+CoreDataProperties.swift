//
//  MRManagedScalarPredictor+CoreDataProperties.swift
//  Muvr
//
//  Created by Jan Machacek on 1/14/16.
//  Copyright © 2016 Muvr. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension MRManagedScalarPredictor {

    @NSManaged var type: String
    @NSManaged var longitude: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var data: NSData

}