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
    
    func setSession(session: MRResistanceExerciseSession, andExamples examples: [MRResistanceExerciseExample]) -> Void {
        title.text = session.title
        let dateString = Consts.dateFormatter.stringFromDate(session.startDate)
        detail.text = "\(session.exerciseModel.title) on \(dateString)"
        chart.setResistenceExercises(examples.flatMap { $0.correct })
    }
}
