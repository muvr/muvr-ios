import UIKit
import MuvrKit

class MRManualViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    private var exerciseType: MKExerciseType? = nil
    private let exerciseTypeDescriptors: [MKExerciseTypeDescriptor] = [
        .ResistanceTargeted,
        .ResistanceWholeBody,
        .IndoorsCardio
    ]
    private let muscleGroups: [MKMuscleGroup] = [
        .Arms, .Back, .Chest, .Core, .Shoulders, .Legs
    ]
    
    /// A list of our checked things. Use ``keyFromIndexPath`` to compute the key Int.
    /// The value indicates whether the item is checked or not.
    private var checked: [Int:Bool] = [:]
    
    override func viewDidAppear(animated: Bool) {
        if exerciseType == nil {
            exerciseType = MRAppDelegate.sharedDelegate().nextExerciseType
            tableView.reloadData()
        }
    }
    
    @IBAction private func start() {
        if let exerciseType = exerciseType {
            try! MRAppDelegate.sharedDelegate().startSession(forExerciseType: exerciseType)
            self.exerciseType = nil
            tableView.reloadData()  
        }
    }
    
    /// Indicates whether the value is checked at the given ``indexPath``
    /// - parameter indexPath: the IP
    /// - returns: checked or not
    private func isCheckedAtIndexPath(indexPath: NSIndexPath) -> Bool {
        guard let exerciseType = exerciseType else { return false }
        
        switch indexPath.section {
        case 0:
            if case .ResistanceTargeted(let mg) = exerciseType {
                return mg.contains(muscleGroups[indexPath.row])
            }
            return false
        case 1: return exerciseType == .ResistanceWholeBody
        case 2: return exerciseType == .IndoorsCardio
        default: return false
        }
    }
    
    /// Returns the cell accessory type for the given ``indexPath``
    /// - parameter indexPath: the IP
    /// - returns: the accessory type
    private func accessoryTypeForIndexPath(indexPath: NSIndexPath) -> UITableViewCellAccessoryType {
        if isCheckedAtIndexPath(indexPath) { return .Checkmark }
        else { return .None }
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
            cell.accessoryType = accessoryTypeForIndexPath(indexPath)
            return cell
        case 1, 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
            cell.textLabel?.text = exerciseTypeDescriptors[indexPath.section].title
            cell.accessoryType = accessoryTypeForIndexPath(indexPath)
            return cell
        default: fatalError()
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // first, deselect all other cells in all other sections
        for s in 0..<numberOfSectionsInTableView(tableView) where s != indexPath.section {
            for r in 0..<self.tableView(tableView, numberOfRowsInSection: s) {
                let ip = NSIndexPath(forRow: r, inSection: s)
                //setCheckedAtIndexPath(ip, value: false)
                tableView.cellForRowAtIndexPath(ip)?.accessoryType = .None
            }
        }

        let checked = !isCheckedAtIndexPath(indexPath) // if unchecked will become checked
        
        // update exercise type according to selected rows
        switch indexPath.section {
        case 0:
            var selectedMuscleGroups: [MKMuscleGroup] = []
            if let exerciseType = exerciseType,
                case .ResistanceTargeted(let mg) = exerciseType {
                    selectedMuscleGroups = mg
            }
            let muscleGroup = muscleGroups[indexPath.row]
            
            if checked { selectedMuscleGroups.append(muscleGroup) }
            else if let index = selectedMuscleGroups.indexOf(muscleGroup) { selectedMuscleGroups.removeAtIndex(index) }
            if selectedMuscleGroups.isEmpty { self.exerciseType = nil }
            else { self.exerciseType = .ResistanceTargeted(muscleGroups: selectedMuscleGroups) }
        case 1 where checked:
            exerciseType = .ResistanceWholeBody
        case 2 where checked:
            exerciseType = .IndoorsCardio
        default:
            exerciseType = nil
        }
        
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = accessoryTypeForIndexPath(indexPath)
        startButton.enabled = exerciseType != nil
    }
}

