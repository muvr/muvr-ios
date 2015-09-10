import Foundation

extension NSDate {

    ///
    /// Computes date only components from an instance that (may) also contains time
    ///
    var dateOnly: NSDate {
        let components = NSCalendar.currentCalendar().components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day], fromDate: self)
        return NSCalendar.currentCalendar().dateFromComponents(components)!
    }

    ///
    /// Adds the specified number of days to this NSDate
    ///
    func addDays(days: Int) -> NSDate {
        return NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.Day, value: days, toDate: self, options: NSCalendarOptions.MatchFirst)!
    }
    
}
