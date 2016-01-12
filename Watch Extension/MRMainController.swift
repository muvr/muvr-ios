import WatchKit
import Foundation
import WatchConnectivity
import MuvrKit

class MRExerciseTypeController: NSObject {
    @IBOutlet var startExerciseType: WKInterfaceButton!
    
    var exerciseType: MKExerciseType? = nil
    var mainController: MRMainController? = nil
    
    func setType(type: MKExerciseType, mainCtrl: MRMainController) {
        exerciseType = type
        startExerciseType.setTitle(exerciseType?.fullname)
        mainController = mainCtrl
    }
    
    @IBAction func beginSessionWithType() {
        mainController?.beginSession(exerciseType!)
    }
}

class MRExerciseRow: NSObject {
    @IBOutlet weak var textLabel: WKInterfaceLabel!
    
    func setExercise(exercise: (String, String)) {
        textLabel.setText(exercise.1)
    }
}

class MRMainController: WKInterfaceController, MRSessionProgressRing, MRSessionHealth {
    @IBOutlet weak var progressGroup: WKInterfaceGroup!
    @IBOutlet weak var innerRing: WKInterfaceGroup!
    @IBOutlet weak var outerRing: WKInterfaceGroup!
    @IBOutlet weak var timeLabel: WKInterfaceLabel!
    @IBOutlet weak var ringLabel: WKInterfaceLabel!
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var heartGroup: WKInterfaceGroup!
    @IBOutlet weak var heartLabel: WKInterfaceLabel!
    @IBOutlet weak var energyLabel: WKInterfaceLabel!
    @IBOutlet weak var energyGroup: WKInterfaceGroup!
    @IBOutlet weak var sessionLabel: WKInterfaceLabel!
    @IBOutlet weak var startGroup: WKInterfaceGroup!
    @IBOutlet weak var exercisesTable: WKInterfaceTable!
    @IBOutlet var exerciseTypeTable: WKInterfaceTable!

    
    private let exercises = [
        ("demo-bc-only", "Biceps curl"),
        ("demo-te-only", "Triceps extension"),
        ("demo-lr-only", "Lateral raise")
    ]
    
    private let exerciseType: [MKExerciseType] = [
        MKExerciseType.ResistanceWholeBody,
        MKExerciseType.ResistanceTargeted(muscleGroups: [MKMuscleGroup.Arms]),
        MKExerciseType.ResistanceTargeted(muscleGroups: [MKMuscleGroup.Back]),
        MKExerciseType.ResistanceTargeted(muscleGroups: [MKMuscleGroup.Chest]),
        MKExerciseType.ResistanceTargeted(muscleGroups: [MKMuscleGroup.Core]),
        MKExerciseType.ResistanceTargeted(muscleGroups: [MKMuscleGroup.Legs]),
        MKExerciseType.ResistanceTargeted(muscleGroups: [MKMuscleGroup.Shoulders])
    ]

    private var renderer: MRSessionProgressRingRenderer?

    private var exerciseModelMetadataIndex: Int = 0
    
    override func willActivate() {
        super.willActivate()
        activate()
    }
    
    private func activate() {
        updateUI()
        if renderer == nil {
            renderer = MRSessionProgressRingRenderer(ring: self, health: self)
        }
    }
    
    override func didAppear() {
        if renderer == nil {
            activate()
        }
    }
    
    override func didDeactivate() {
        renderer?.deactivate()
        renderer = nil
        super.didDeactivate()
    }
    
    private func updateUI() {
        let sd = MRExtensionDelegate.sharedDelegate()
        clearAllMenuItems()
        
        exerciseTypeTable.setNumberOfRows(exerciseType.count, withRowType: "MRExerciseTypeController")
                NSLog("count = \(exerciseType.count)")
                NSLog("table = \(exerciseTypeTable.numberOfRows)")
        (0..<exerciseTypeTable.numberOfRows).forEach { i in
            let row = exerciseTypeTable.rowControllerAtIndex(i) as! MRExerciseTypeController
            row.setType(exerciseType[i], mainCtrl: self)
        }
        
        if let (_, _) = sd.currentSession {
            addMenuItemWithItemIcon(WKMenuItemIcon.Pause, title: "Pause", action: "pause")
            addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Stop",  action: "stop")

            // TODO: real session will probably want to display plan or something
            exercisesTable.setNumberOfRows(0, withRowType: "exercise")
        } else {
            // NB. this is correct; even though it looks exactly like the line above,
            // NB. it will stay like this.
            exercisesTable.setNumberOfRows(0, withRowType: "exercise")
        }
        progressGroup.setHidden(sd.currentSession == nil)
        startGroup.setHidden(sd.currentSession != nil)
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
    }
    
    func pause() {
        
    }
    
    func stop() {
        MRExtensionDelegate.sharedDelegate().endLastSession()
        renderer?.reset()
        updateUI()
    }
    
    ///
    /// Called when the user clicks the session start button
    ///
    func beginSession(exerType: MKExerciseType) {
        renderer?.reset()
        MRExtensionDelegate.sharedDelegate().startSession(exerciseModelMetadataIndex: exerciseModelMetadataIndex, exerciseType: exerType)
        updateUI()
    }

}

extension WKPickerItem {
    
    static func withTitle(title: String) -> WKPickerItem {
        let i = WKPickerItem()
        i.title = title
        return i
    }
    
}
