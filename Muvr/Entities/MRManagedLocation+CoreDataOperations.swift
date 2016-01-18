//
//  MRManagedLocation+CoreDataOperations.swift
//  Muvr
//
//  Created by Jan Machacek on 1/16/16.
//  Copyright © 2016 Muvr. All rights reserved.
//

import Foundation
import CoreData

extension MRManagedLocation {
    
    static func findAtLocation(location: MRLocationCoordinate2D, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedLocation? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedLocation")
        fetchRequest.predicate = NSPredicate(location: location)
        
        return (try! managedObjectContext.executeFetchRequest(fetchRequest) as! [MRManagedLocation]).first
    }

    static func upsertFromJSON(json: NSDictionary, inManagedObjectContext managedObjectContext: NSManagedObjectContext) throws {
        guard let latitude = json["latitude"] as? NSNumber,
            let longitude = json["longitude"] as? NSNumber,
            let name = json["name"] as? String else { return }
        
        let fetchRequest = NSFetchRequest(entityName: "MRManagedLocation")
        fetchRequest.predicate = NSPredicate(latitude: latitude.doubleValue, longitude: longitude.doubleValue)
        if let existing = try managedObjectContext.executeFetchRequest(fetchRequest).first as? NSManagedObject {
            // TODO: fixme
            // fatalError("This needs updating. The objectID needs to remain stable.")
        }
        
        let mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedLocation", inManagedObjectContext: managedObjectContext) as! MRManagedLocation
        
        mo.latitude = latitude.doubleValue
        mo.longitude = longitude.doubleValue
        mo.name = name
        
        (json["exercises"] as? NSArray)?.forEach { e in
            if let l = e as? NSDictionary {
                MRManagedLocationExercise.insertNewObjectFromJSON(l, location: mo, inManagedObjectContext: managedObjectContext)
            }
        }
    }
}
