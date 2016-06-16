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
    
    
    /// A list of our checked things. Use ``keyFromIndexPath`` to compute the key Int.
    /// The value indicates whether the item is checked or not.
    private var checked: [Int:Bool] = [:]
    
    @IBAction private func start() {
        if let exerciseType = exerciseType {
            try! MRAppDelegate.sharedDelegate().startSession(.AdHoc(exerciseType: exerciseType))
        }
    }
    
    /// Computes the key from the given ``indexPath``
    /// - parameter indexPath: the IP
    /// - returns: the key to be used in the ``checked`` dictionary
    private func keyFromIndexPath(_ indexPath: IndexPath) -> Int {
        return (indexPath as NSIndexPath).section * 1024 + (indexPath as NSIndexPath).row
    }
    
    /// Indicates whether the value is checked at the given ``indexPath``
    /// - parameter indexPath: the IP
    /// - returns: checked or not
    private func isCheckedAtIndexPath(_ indexPath: IndexPath) -> Bool {
        return checked[keyFromIndexPath(indexPath)] ?? false
    }
    
    /// Sets the checked value at the given ``indexPath``
    /// - parameter indexPath: the IP
    /// - parameter value: the new value
    private func setCheckedAtIndexPath(_ indexPath: IndexPath, value: Bool) {
        checked[keyFromIndexPath(indexPath)] = value
    }
    
    /// Returns the cell accessory type for the given ``indexPath``
    /// - parameter indexPath: the IP
    /// - returns: the accessory type
    private func accessoryTypeForIndexPath(_ indexPath: IndexPath) -> UITableViewCellAccessoryType {
        if isCheckedAtIndexPath(indexPath) {
            return .checkmark
        } else {
            return .none
        }
    }
    
    /// Inverts the checked value at the ``indexPath``
    /// - parameter indexPath: the IP
    /// - returns: the new value
    private func toggleCheckedAtIndexPath(_ indexPath: IndexPath) -> Bool {
        let value = !isCheckedAtIndexPath(indexPath)
        setCheckedAtIndexPath(indexPath, value: value)
        return value
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return exerciseTypeDescriptors.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return muscleGroups.count
        case 1, 2: return 1
        default: fatalError()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return exerciseTypeDescriptors[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath as NSIndexPath).section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = muscleGroups[indexPath.row].title
            cell.accessoryType = accessoryTypeForIndexPath(indexPath)
            return cell
        case 1, 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = exerciseTypeDescriptors[indexPath.section].title
            cell.accessoryType = accessoryTypeForIndexPath(indexPath)
            return cell
        default: fatalError()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // first, deselect all other cells in all other sections
        for s in 0..<numberOfSections(in: tableView) where s != (indexPath as NSIndexPath).section {
            for r in 0..<self.tableView(tableView, numberOfRowsInSection: s) {
                let ip = IndexPath(row: r, section: s)
                setCheckedAtIndexPath(ip, value: false)
                tableView.cellForRow(at: ip)?.accessoryType = .none
            }
        }

        let checked = toggleCheckedAtIndexPath(indexPath)
        tableView.cellForRow(at: indexPath)?.accessoryType = accessoryTypeForIndexPath(indexPath)
        
        switch (indexPath as NSIndexPath).section {
        case 0:
            var selectedMuscleGroups: [MKMuscleGroup] = []
            for r in 0..<self.tableView(tableView, numberOfRowsInSection: (indexPath as NSIndexPath).section) {
                if isCheckedAtIndexPath(IndexPath(row: r, section: (indexPath as NSIndexPath).section)) {
                    selectedMuscleGroups.append(muscleGroups[r])
                }
            }
            if selectedMuscleGroups.isEmpty {
                exerciseType = nil
            } else {
                exerciseType = .ResistanceTargeted(muscleGroups: selectedMuscleGroups)
            }
        case 1 where checked:
            exerciseType = .ResistanceWholeBody
        case 2 where checked:
            exerciseType = .IndoorsCardio
        default:
            exerciseType = nil
        }
        
        startButton.enabled = exerciseType != nil
    }
}

