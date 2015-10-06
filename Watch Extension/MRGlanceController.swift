import WatchKit
import Foundation
import HealthKit

class MRGlanceController: WKInterfaceController {

    private func workoutPredicate() -> NSPredicate {
        
        func currentWeekDates()-> (start: NSDate, end: NSDate) {
            // Sunday 1, Monday 2, Tuesday 3, Wednesday 4, Friday 5, Saturday 6
            let calendar = NSCalendar.currentCalendar()
            calendar.firstWeekday = NSCalendar.currentCalendar().firstWeekday
            var start: NSDate? = nil
            var duration: NSTimeInterval = 0
            
            calendar.rangeOfUnit(NSCalendarUnit.WeekOfYear, startDate: &start, interval: &duration, forDate: NSDate())
            return (start!, start!.dateByAddingTimeInterval(duration))
        }
        
        let (s, e) = currentWeekDates()
        let workout = HKWorkout(activityType: HKWorkoutActivityType.FunctionalStrengthTraining, startDate: s, endDate: e)
        return HKQuery.predicateForObjectsFromWorkout(workout)
    }
    
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)        
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
