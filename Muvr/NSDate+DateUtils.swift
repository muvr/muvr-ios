import Foundation

extension NSDate {

    ///
    /// Computes date only components from an instance that (may) also contains time
    ///
    var dateOnly: NSDate {
        let components = NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitDay, fromDate: self)
        return NSCalendar.currentCalendar().dateFromComponents(components)!
    }
    
}
