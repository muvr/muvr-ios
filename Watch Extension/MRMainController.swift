import WatchKit
import Foundation
import WatchConnectivity
import MuvrKit

class MRMainController: WKInterfaceController, MRSessionProgressGroup {
    @IBOutlet weak var exerciseModel: WKInterfacePicker!
    @IBOutlet weak var startGroup: WKInterfaceGroup!
    @IBOutlet weak var progressGroup: WKInterfaceGroup!
    
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var timeLabel: WKInterfaceLabel!
    @IBOutlet weak var statsLabel: WKInterfaceLabel!

    private var renderer: MRSessionProgressGroupRenderer?

    private var exerciseModelMetadataIndex: Int = 0
    
    override func willActivate() {
        super.willActivate()
        let sd = MRExtensionDelegate.sharedDelegate()
        exerciseModel.setItems(sd.getExerciseModelMetadata().map { _, title in return WKPickerItem.withTitle(title) })
        sd.getCurrentSession()?.beginSendBatch()
        
        updateUI()
        renderer = MRSessionProgressGroupRenderer(group: self)
    }
    
    override func didDeactivate() {
        renderer = nil
        super.didDeactivate()
    }
    
    private func updateUI() {
        let sd = MRExtensionDelegate.sharedDelegate()
        clearAllMenuItems()
        if sd.getCurrentSession() != nil {
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
    
    ///
    /// Called when the user clicks the session start button
    ///
    @IBAction func beginSession() {
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
