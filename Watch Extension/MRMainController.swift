import WatchKit
import Foundation
import WatchConnectivity
import MuvrKit

class MRMainController: WKInterfaceController {
    @IBOutlet weak var model: WKInterfacePicker!
    @IBOutlet weak var intensity: WKInterfacePicker!
    @IBOutlet weak var startGroup: WKInterfaceGroup!
    @IBOutlet weak var progressGroup: WKInterfaceGroup!
    
    @IBOutlet weak var modelLabel: WKInterfaceLabel!
    @IBOutlet weak var intensityLabel: WKInterfaceLabel!
    
    private var modelMetadataIndex: Int = 0
    private var intensityIndex: Int = 0
    
    override func willActivate() {
        super.willActivate()
        let sd = MRExtensionDelegate.sharedDelegate()
        model.setItems(sd.getModelMetadata().map { _, title in return WKPickerItem.withTitle(title) })
        intensity.setItems(sd.getIntensities().map { x in WKPickerItem.withTitle(x.title) })
        
        updateUI()
    }
    
    private func updateUI() {
        let sd = MRExtensionDelegate.sharedDelegate()
        clearAllMenuItems()
        if let session = sd.getCurrentSession() {
            modelLabel.setText(session.modelTitle)
            intensityLabel.setText(session.intensityTitle)
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
        MRExtensionDelegate.sharedDelegate().startSession(modelMetadataIndex: modelMetadataIndex, intensityIndex: intensityIndex)
        updateUI()
    }
    
    @IBAction func modelPickerAction(index: Int) {
        modelMetadataIndex = index
    }

    @IBAction func intensityPickerAction(index: Int) {
        intensityIndex = index
    }
}

extension WKPickerItem {
    
    static func withTitle(title: String) -> WKPickerItem {
        let i = WKPickerItem()
        i.title = title
        return i
    }
    
}
