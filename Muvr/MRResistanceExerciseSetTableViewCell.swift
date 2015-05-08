import Foundation

class MRResistanceExerciseSetTableViewCell : UITableViewCell {
    @IBOutlet var title: UILabel!
    @IBOutlet var detail: UILabel!
    @IBOutlet var chart: MRResistanceExerciseSetIntensityView!
    
    func setSession(session: MRResistanceExerciseSession, andSets sets: [MRResistanceExerciseSet]) -> Void {
        title.text = ", ".join(session.properties.muscleGroupIds)
        detail.text = "Some such"
        chart.setResistenceExerciseSets(sets)
    }
}