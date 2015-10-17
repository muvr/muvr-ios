import WatchKit
import Foundation
import WatchConnectivity
import MuvrKit

class MRMainController: WKInterfaceController {
    @IBOutlet weak var exerciseModel: WKInterfacePicker!
    @IBOutlet weak var startGroup: WKInterfaceGroup!
    @IBOutlet weak var progressGroup: WKInterfaceGroup!
    
    @IBOutlet weak var exerciseStartStopButton: WKInterfaceButton!
    @IBOutlet weak var exerciseModelLabel: WKInterfaceLabel!
    
    private var exerciseModelMetadataIndex: Int = 0
    
    override func willActivate() {
        super.willActivate()
        let sd = MRExtensionDelegate.sharedDelegate()
        exerciseModel.setItems(sd.getExerciseModelMetadata().map { _, title in return WKPickerItem.withTitle(title) })
        sd.getCurrentSession()?.beginSendBatch()
        
        updateUI()
    }
    
    private func updateExerciseStartStopButton() {
        if let session = MRExtensionDelegate.sharedDelegate().getCurrentSession() {
            if session.isRealTime {
                exerciseStartStopButton.setTitle("Stop")
                exerciseStartStopButton.setBackgroundImageNamed("stop")
            } else {
                exerciseStartStopButton.setTitle("Go")
                exerciseStartStopButton.setBackgroundImageNamed("go")
            }
        }
    }
    
    private func updateUI() {
        let sd = MRExtensionDelegate.sharedDelegate()
        clearAllMenuItems()
        if let session = sd.getCurrentSession() {
            exerciseModelLabel.setText(session.exerciseModelTitle)
            addMenuItemWithItemIcon(WKMenuItemIcon.Pause, title: "Pause", action: "pause")
            addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Stop",  action: "stop")
        }
        
        updateExerciseStartStopButton()
        
        progressGroup.setHidden(sd.getCurrentSession() == nil)
        startGroup.setHidden(sd.getCurrentSession() != nil)
    }
    
    func pause() {
        
    }
    
    func stop() {
        MRExtensionDelegate.sharedDelegate().endSession()
        updateUI()
    }
    
    ///
    /// Called when the user clicks the session start button
    ///
    @IBAction func beginSession() {
        MRExtensionDelegate.sharedDelegate().startSession(exerciseModelMetadataIndex: exerciseModelMetadataIndex)
        updateUI()
    }
    
    ///
    /// Called when the user clicks the exercise start or stop button
    ///
    @IBAction func beginOrEndExercise() {
        if let session = MRExtensionDelegate.sharedDelegate().getCurrentSession() {
            if session.isRealTime {
                session.endSendRealTime(updateExerciseStartStopButton)
            } else {
                session.beginSendRealTime(updateExerciseStartStopButton)
            }
        }
    }
    
    @IBAction func exerciseModelPickerAction(index: Int) {
        exerciseModelMetadataIndex = index
    }

}

extension WKPickerItem {
    
    static func withTitle(title: String) -> WKPickerItem {
        let i = WKPickerItem()
        i.title = title
        return i
    }
    
}
