import Foundation

extension NSDate {
    
    struct Formatter {
        static let isoDateFormatter: NSDateFormatter = {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            return dateFormatter
            }()
    }

    func marshal() -> String {
        return Formatter.isoDateFormatter.stringFromDate(self)
    }
    
    static func unmarshal(s: String) -> NSDate {
        return Formatter.isoDateFormatter.dateFromString(s)!
    }
    
}
