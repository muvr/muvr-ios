import Foundation

extension MRDataModel {
    
    static func loadArray<A>(basename: String, unmarshal: JSON -> A) -> (NSLocale, [A])? {
        func getJSONFileName() -> (NSLocale, String?) {
            let locale = NSLocale.currentLocale()
            let locid = locale.localeIdentifier
            if let x = NSBundle.mainBundle().pathForResource("default-\(basename)_\(locid)", ofType: "json") { return (locale, x) }
            return (NSLocale(localeIdentifier: "en"), NSBundle.mainBundle().pathForResource("default-\(basename)", ofType: "json"))
        }
        
        switch getJSONFileName() {
        case (let l, .Some(let x)):
            if let data = NSData(contentsOfFile: x) {
                NSLog("Loading data from json file %@", x)
                // NSLog("%@", NSString(data: data, encoding: NSUTF8StringEncoding)!)
                if let jo: AnyObject = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) {
                    return (l, JSON(jo).arrayValue.map(unmarshal))
                }
            }
        default: return nil
        }
        
        return nil
    }
        
}
