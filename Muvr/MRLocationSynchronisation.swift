import Foundation
import CoreData

class MRLocationSynchronisation {
    
    func synchronise(inManagedObjectContext managedObjectContext: NSManagedObjectContext) throws {
        let bundlePath = Bundle.main().pathForResource("Locations", ofType: "bundle")!
        let locationsBundle = Bundle(path: bundlePath)!
        let resourcesURL = URL(fileURLWithPath: locationsBundle.resourcePath!)
        let files = try FileManager.default().contentsOfDirectory(atPath: locationsBundle.resourcePath!)
        for file in files {
            let fileURL = try! resourcesURL.appendingPathComponent(file)
            if fileURL.pathExtension == "json" {
                let data = try! Data(contentsOf: fileURL)
                let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                if let root = json as? NSDictionary {
                    try MRManagedLocation.upsertFromJSON(root, inManagedObjectContext: managedObjectContext)
                }
            }
        }
    }
    
}
