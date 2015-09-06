import Foundation

class MRResistanceExerciseTableViewCell : UITableViewCell {
    @IBOutlet var title: UILabel!
    @IBOutlet var detail: UILabel!
    @IBOutlet var chart: MRResistanceExerciseIntensityView!
    
    private struct Consts {
        static let dateFormatter: NSDateFormatter = {
            let df = NSDateFormatter()
            df.dateStyle = NSDateFormatterStyle.ShortStyle
            df.timeStyle = NSDateFormatterStyle.NoStyle
            return df
        }()
    }
    
    func setSession(session: MRResistanceExerciseSession, andExercises exercises: [MRClassifiedResistanceExercise]) -> Void {
        title.text = ", ".join(session.exerciseModel.exercises)
        let dateString = Consts.dateFormatter.stringFromDate(session.startDate)
        detail.text = "\(session.title) on \(dateString)"
        chart.setResistenceExercises(exercises)
    }
}
