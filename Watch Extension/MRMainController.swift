import WatchKit
import Foundation
import WatchConnectivity
import MuvrKit

class MRMainController: WKInterfaceController {
    @IBOutlet weak var exerciseModel: WKInterfacePicker!
    @IBOutlet weak var startGroup: WKInterfaceGroup!
    @IBOutlet weak var progressGroup: WKInterfaceGroup!
    
    @IBOutlet weak var exerciseModelLabel: WKInterfaceLabel!
    
    private var exerciseModelMetadataIndex: Int = 0
    
    override func willActivate() {
        super.willActivate()
        let sd = MRExtensionDelegate.sharedDelegate()
        exerciseModel.setItems(sd.getExerciseModelMetadata().map { _, title in return WKPickerItem.withTitle(title) })
        sd.getCurrentSession()?.sendImmediately()
        
        updateUI()
    }
    
    private func updateUI() {
        let sd = MRExtensionDelegate.sharedDelegate()
        clearAllMenuItems()
        if let session = sd.getCurrentSession() {
            exerciseModelLabel.setText(session.exerciseModelTitle)
            addMenuItemWithItemIcon(WKMenuItemIcon.Pause, title: "Pause", action: "pause")
            addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Stop",  action: "stop")
        }
        progressGroup.setHidden(sd.getCurrentSession() == nil)
        startGroup.setHidden(sd.getCurrentSession() != nil)
    }
    
    func pause() {
        
    }
    
    func stop() {
        MRExtensionDelegate.sharedDelegate().endSession()
        updateUI()
    }
    
    @IBAction func go() {
        MRExtensionDelegate.sharedDelegate().startSession(exerciseModelMetadataIndex: exerciseModelMetadataIndex)
        updateUI()
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
