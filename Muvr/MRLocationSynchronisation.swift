import Foundation
import CoreData

class MRLocationSynchronisation {
    
    func synchronise(inManagedObjectContext managedObjectContext: NSManagedObjectContext) throws {
        let bundlePath = NSBundle.mainBundle().pathForResource("Locations", ofType: "bundle")!
        let locationsBundle = NSBundle(path: bundlePath)!
        let resourcesURL = NSURL(fileURLWithPath: locationsBundle.resourcePath!)
        let files = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(locationsBundle.resourcePath!)
        for file in files {
            let fileURL = resourcesURL.URLByAppendingPathComponent(file)
            if fileURL.pathExtension == "json" {
                let data = NSData(contentsOfURL: fileURL)!
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
                if let root = json as? NSDictionary {
                    try MRManagedLocation.upsertFromJSON(root, inManagedObjectContext: managedObjectContext)
                }
            }
        }
    }
    
}
