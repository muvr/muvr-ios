import Foundation

extension Date {
    
    ///
    /// Computes date only components from an instance that (may) also contains time
    ///
    var dateOnly: Date {
        let components = Calendar.current().components([Calendar.Unit.year, Calendar.Unit.month, Calendar.Unit.day], from: self)
        return Calendar.current().date(from: components)!
    }
    
    ///
    /// Adds the specified number of days to this NSDate
    ///
    func addDays(_ days: Int) -> Date {
        return Calendar.current().date(byAdding: Calendar.Unit.day, value: days, to: self, options: Calendar.Options.matchFirst)!
    }
    
    ///
    /// Adds the specified number of hours to this NSDate
    ///
    func addHours(_ hours: Int) -> Date {
        return Calendar.current().date(byAdding: Calendar.Unit.hour, value: hours, to: self, options: Calendar.Options.matchFirst)!
    }
    
    ///
    /// Adds the specified number of seconds to this NSDate
    ///
    func addSeconds(_ seconds: Int) -> Date {
        return Calendar.current().date(byAdding: Calendar.Unit.second, value: seconds, to: self, options: Calendar.Options.matchFirst)!
    }
    
    ///
    /// returns a string (HH:mm) representing the time of this NSDate
    func formatTime() -> String {
        let format = DateFormatter()
        format.dateFormat = "HH:mm"
        return format.string(from: self)
    }
    
    ///
    /// returns a string ``YYYYMMddTHHmmssZ`` UTC
    ///
    var utcString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(forSecondsFromGMT: 0)
        return dateFormatter.string(from: self)
    }
    
}
