import WatchKit
import Foundation
import WatchConnectivity
import MuvrKit

class MRMainController: WKInterfaceController {
    @IBOutlet var model: WKInterfacePicker!
    @IBOutlet var intensity: WKInterfacePicker!
    
    override func willActivate() {
        super.willActivate()
        model.setItems(MRExtensionDelegate.sharedDelegate().modelMetadata.map { _, title in return WKPickerItem.withTitle(title) })
        intensity.setItems(MRExtensionDelegate.sharedDelegate().intensities.map { x in WKPickerItem.withTitle(x.title) })
    }
    
    @IBAction func go() {
        pushControllerWithName("Exercising", context: nil)
    }
}

extension WKPickerItem {
    
    static func withTitle(title: String) -> WKPickerItem {
        let i = WKPickerItem()
        i.title = title
        return i
    }
    
}
