import Foundation

struct MRMuscleGroupRepository {
    
    static func load() -> [MRMuscleGroup] {
        func getJSONFileName() -> String? {
            let locid = NSLocale.currentLocale().localeIdentifier
            if let x = NSBundle.mainBundle().pathForResource("musclegroups_\(locid)", ofType: "json") { return x }
            return NSBundle.mainBundle().pathForResource("musclegroups", ofType: "json")
        }
        
        if let x = getJSONFileName() {
            if let data = NSData(contentsOfFile: x) {
                if let jo: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) {
                    return JSON(jo).arrayValue.map(MRMuscleGroup.unmarshal)
                }
            }
        }
        
        return []
    }
    
    static func save(data: NSData) {
        fatalError("implement me.")
    }
    
}
