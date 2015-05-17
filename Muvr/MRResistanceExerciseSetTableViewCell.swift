import Foundation

class MRResistanceExerciseSetTableViewCell : UITableViewCell {
    @IBOutlet var title: UILabel!
    @IBOutlet var detail: UILabel!
    @IBOutlet var chart: MRResistanceExerciseSetIntensityView!
    
    private struct Consts {
        static let dateFormatter: NSDateFormatter = {
            let df = NSDateFormatter()
            df.dateStyle = NSDateFormatterStyle.ShortStyle
            df.timeStyle = NSDateFormatterStyle.NoStyle
            return df
        }()
    }
    
    func setSession(session: MRResistanceExerciseSession, andSets sets: [MRResistanceExerciseSet]) -> Void {
        title.text = MRApplicationState.joinMuscleGroups(session.muscleGroupIds)
        let dateString = Consts.dateFormatter.stringFromDate(session.startDate)
        detail.text = "\(session.title) on \(dateString)"
        chart.setResistenceExerciseSets(sets)
    }
}
