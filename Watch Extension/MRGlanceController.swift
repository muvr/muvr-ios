import WatchKit
import Foundation
import HealthKit

class MRGlanceController: WKInterfaceController {
    @IBOutlet weak var titleLable: WKInterfaceLabel!
    @IBOutlet weak var batchCounterLabel: WKInterfaceLabel!
    @IBOutlet weak var realTimeCounterLabel: WKInterfaceLabel!

//    private func workoutPredicate() -> NSPredicate {
//        
//        func currentWeekDates()-> (start: NSDate, end: NSDate) {
//            // Sunday 1, Monday 2, Tuesday 3, Wednesday 4, Friday 5, Saturday 6
//            let calendar = NSCalendar.currentCalendar()
//            calendar.firstWeekday = NSCalendar.currentCalendar().firstWeekday
//            var start: NSDate? = nil
//            var duration: NSTimeInterval = 0
//            
//            calendar.rangeOfUnit(NSCalendarUnit.WeekOfYear, startDate: &start, interval: &duration, forDate: NSDate())
//            return (start!, start!.dateByAddingTimeInterval(duration))
//        }
//        
//        let (s, e) = currentWeekDates()
//        let workout = HKWorkout(activityType: HKWorkoutActivityType.FunctionalStrengthTraining, startDate: s, endDate: e)
//        return HKQuery.predicateForObjectsFromWorkout(workout)
//    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)        
    }
    
    override func willActivate() {
        super.willActivate()

        if let session = MRExtensionDelegate.sharedDelegate().getCurrentSession() {
            let text = NSDateComponentsFormatter().stringFromTimeInterval(session.sessionDuration)!
            session.beginSendBatch()
            titleLable.setText("Exercising \(text)")
            let batch = session.sessionStats.batchCounter
            batchCounterLabel.setText("R \(batch.recorded), S \(batch.sent)")
            if let rt = session.sessionStats.realTimeCounter {
                realTimeCounterLabel.setText("R \(rt.recorded), S \(rt.sent)")
            } else {
                realTimeCounterLabel.setText("")
            }
        } else {
            titleLable.setText("Idle")
            batchCounterLabel.setText(buildDate())
            realTimeCounterLabel.setText("")
        }
    }

    override func didDeactivate() {
        super.didDeactivate()
    }

}
