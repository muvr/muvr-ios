import UIKit

class MRExerciseSetTableViewCell : UITableViewCell {
    static let nib: UINib = UINib(nibName: "MRExerciseSetTableViewCell", bundle: nil)
    static let cellReuseIdentifier: String = "set"
    
    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var setSizeLabel: UILabel!
    
    func setSet(set: [MRManagedClassifiedExercise]) {
        assert(!set.isEmpty, "The set cannot be empty")
        set.forEach { x in assert(x.exerciseId == set.first!.exerciseId, "The set must be all same exercise ids") }
        
        exerciseLabel.text = set.first!.exerciseId
        if set.count == 1 {
            setSizeLabel.text = "1 set"
        } else {
            setSizeLabel.text = "\(set.count) sets"
        }
    }
    
}

//        switch indexPath.section {
//        case 0:
//            let cell = tableView.dequeueReusableCellWithIdentifier("classifiedExercise", forIndexPath: indexPath)
//            let ce = session!.classifiedExercises.reverse()[indexPath.row] as! MRManagedClassifiedExercise
//            cell.textLabel!.text = ce.exerciseId
//            let weight = ce.weight.map { w in "\(NSString(format: "%.2f", w)) kg" } ?? ""
//            let intensity = ce.intensity.map { i in "Intensity: \(NSString(format: "%.2f", i))" } ?? ""
//            let duration = "\(NSString(format: "%.0f", ce.duration))s"
//            let repetitions = ce.repetitions.map { r in "x\(r)" } ?? ""
//            cell.detailTextLabel!.text = "\(ce.start.formatTime()) - \(duration) - \(repetitions) - \(weight) - \(intensity)"
//            guard let imageView = cell.viewWithTag(10) as? UIImageView else { return cell }
//            if let match = matchLabel(ce) {
//                imageView.image = UIImage(named: match ? "tick" : "miss")
//            } else {
//                imageView.image = nil
//            }
//            return cell
//        case 1:
//            let cell = tableView.dequeueReusableCellWithIdentifier("labelledExercise", forIndexPath: indexPath)
//            let le = session!.labelledExercises.reverse()[indexPath.row] as! MRManagedLabelledExercise
//            cell.textLabel!.text = le.exerciseId
//            let weight = "\(NSString(format: "%.2f", le.weight)) kg"
//            let intensity = "Intensity: \(NSString(format: "%.2f", le.intensity))"
//            let duration = "\(NSString(format: "%.0f", le.end.timeIntervalSince1970 - le.start.timeIntervalSince1970))s"
//            let repetitions = "x\(le.repetitions)"
//            cell.detailTextLabel!.text = "\(le.start.formatTime()) - \(duration) - \(repetitions) - \(weight) - \(intensity)"
//            return cell
//        default:
//            fatalError()
//        }
