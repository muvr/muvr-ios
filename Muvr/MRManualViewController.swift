import UIKit
import MuvrKit

class MRManualViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet private weak var startButton: UIButton!
    private var exerciseType: MKExerciseType? = nil
    private let exerciseTypeDescriptors: [MKExerciseTypeDescriptor] = [
        .ResistanceTargeted,
        .ResistanceWholeBody,
        .IndoorsCardio
    ]
    private let muscleGroups: [MKMuscleGroup] = [
        .Arms, .Back, .Chest, .Core, .Shoulders, .Legs
    ]
    
    @IBAction private func start() {
        if let exerciseType = exerciseType {
            try! MRAppDelegate.sharedDelegate().startSessionForExerciseType(exerciseType, start: NSDate(), id: NSUUID().UUIDString)
        }
    }

    // MARK: - UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return exerciseTypeDescriptors.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return muscleGroups.count
        case 1, 2: return 1
        default: fatalError()
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return exerciseTypeDescriptors[section].title
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
            cell.textLabel?.text = muscleGroups[indexPath.row].title
            return cell
        case 1, 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
            cell.textLabel?.text = exerciseTypeDescriptors[indexPath.section].title
            return cell
        default: fatalError()
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // first, deselect all other cells in all other sections
        for s in 0..<numberOfSectionsInTableView(tableView) where s != indexPath.section {
            for r in 0..<self.tableView(tableView, numberOfRowsInSection: s) {
                tableView.cellForRowAtIndexPath(NSIndexPath(forRow: r, inSection: s))!.accessoryType = .None
            }
        }

        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        if cell.accessoryType == .None {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        
        switch indexPath.section {
        case 0:
            var selectedMuscleGroups: [MKMuscleGroup] = []
            for r in 0..<self.tableView(tableView, numberOfRowsInSection: indexPath.section) {
                if tableView.cellForRowAtIndexPath(NSIndexPath(forRow: r, inSection: indexPath.section))!.accessoryType == .Checkmark {
                    selectedMuscleGroups.append(muscleGroups[r])
                }
            }
            if selectedMuscleGroups.isEmpty {
                exerciseType = nil
            } else {
                exerciseType = .ResistanceTargeted(muscleGroups: selectedMuscleGroups)
            }
        case 1 where cell.accessoryType == .Checkmark:
            exerciseType = .ResistanceWholeBody
        case 2 where cell.accessoryType == .Checkmark:
            exerciseType = .IndoorsCardio
        default:
            exerciseType = nil
        }
        
        startButton.enabled = exerciseType != nil
    }
}

