import WatchKit
import Foundation
import WatchConnectivity
import MuvrKit

class MRExerciseTypeController: NSObject {
    @IBOutlet var startExerciseType: WKInterfaceButton!
    
    var exerciseType: MKExerciseType!
    var mainController: MRMainController!
    
    func setExerciseType(exerciseType: MKExerciseType, mainController: MRMainController) {
        self.exerciseType = exerciseType
        startExerciseType.setTitle(exerciseType.title)
        self.mainController = mainController
    }
    
    @IBAction func beginSessionWithType() {
        mainController.beginSession(exerciseType)
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
    
    override func willActivate() {
        super.willActivate()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MRMainController.sessionDidStart(_:)), name: MRNotifications.CurrentSessionDidStart.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MRMainController.sessionDidEnd(_:)), name: MRNotifications.CurrentSessionDidEnd.rawValue, object: nil)
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
        NSNotificationCenter.defaultCenter().removeObserver(self)
        super.didDeactivate()
    }
    
    private func updateUI(withEndedSession endedSessionId: String? = nil) {
        clearAllMenuItems()
        
        let session = MRExtensionDelegate.sharedDelegate().currentSession
        let active = session != nil && session?.0.id != endedSessionId
        
        exerciseTypeTable.setNumberOfRows(exerciseType.count, withRowType: "MRExerciseTypeController")
        (0..<exerciseTypeTable.numberOfRows).forEach { i in
            let row = exerciseTypeTable.rowControllerAtIndex(i) as! MRExerciseTypeController
            row.setExerciseType(exerciseType[i], mainController: self)
        }
        
        if active {
            addMenuItemWithItemIcon(WKMenuItemIcon.Pause, title: "Pause", action: #selector(MRMainController.pause))
            addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Stop",  action: #selector(MRMainController.stop))

            // TODO: real session will probably want to display plan or something
            exercisesTable.setNumberOfRows(0, withRowType: "exercise")
        } else {
            // NB. this is correct; even though it looks exactly like the line above,
            // NB. it will stay like this.
            exercisesTable.setNumberOfRows(0, withRowType: "exercise")
        }
        progressGroup.setHidden(!active)
        startGroup.setHidden(active)
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
    func beginSession(exerciseType: MKExerciseType) {
        renderer?.reset()
        MRExtensionDelegate.sharedDelegate().startSession(exerciseType)
        updateUI()
    }
    
    /// callback function invoked when session is started/ended on the phone
    internal func sessionDidStart(notification: NSNotification) {
        updateUI()
        renderer?.update()
    }
    
    internal func sessionDidEnd(notification: NSNotification) {
        updateUI(withEndedSession: notification.object as? String)
        renderer?.update()
    }

}

extension WKPickerItem {
    
    static func withTitle(title: String) -> WKPickerItem {
        let i = WKPickerItem()
        i.title = title
        return i
    }
    
}
