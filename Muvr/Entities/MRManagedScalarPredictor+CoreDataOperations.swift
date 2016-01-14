//
//  MRManagedScalarPredictor+CoreDataOperations.swift
//  Muvr
//
//  Created by Jan Machacek on 1/14/16.
//  Copyright © 2016 Muvr. All rights reserved.
//

import Foundation
import CoreData
import MuvrKit

extension MRManagedScalarPredictor {
    
    static func exactScalarPredictorFor(type: String, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedScalarPredictor? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedScalarPredictor")
        var predicate = NSPredicate(format: "type = %@", type)
        if let location = location {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, NSPredicate(location: location)])
        }
        fetchRequest.fetchLimit = 10
        
        return (try! managedObjectContext.executeFetchRequest(fetchRequest)).first as? MRManagedScalarPredictor
    }
    
    static func scalarPredictorFor(type: String, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedScalarPredictor? {
        if let exact = exactScalarPredictorFor(type, location: location, inManagedObjectContext: managedObjectContext) {
            return exact
        } else {
            return exactScalarPredictorFor(type, location: nil, inManagedObjectContext: managedObjectContext)
        }
    }
    
    static func upsertScalarPredictor(type: String, data: NSData, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        if let existing = exactScalarPredictorFor(type, location: location, inManagedObjectContext: managedObjectContext) {
            existing.data = data
        } else {
            let mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedScalarPredictor", inManagedObjectContext: managedObjectContext) as! MRManagedScalarPredictor
            mo.type = type
            mo.data = data
            mo.latitude = location?.latitude
            mo.longitude = location?.longitude
        }
    }
    
}

