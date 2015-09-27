import WatchKit
import Foundation
import WatchConnectivity
import MuvrKit

class MRMainController: WKInterfaceController {
    @IBOutlet var model: WKInterfacePicker!
    @IBOutlet var intensity: WKInterfacePicker!
    
    override func willActivate() {
        super.willActivate()
        model.setItems(MRExtensionDelegate.sharedDelegate().models.map { $0.pickerItem })
        intensity.setItems(MRExtensionDelegate.sharedDelegate().intensities.map { $0.pickerItem })
    }
    
    @IBAction func go() {
        pushControllerWithName("Exercising", context: nil)
    }
}

extension MKExerciseModel {
    
    var pickerItem: WKPickerItem {
        let i = WKPickerItem()
        i.title = title
        return i
    }
    
}

extension MKIntensity {
    
    var pickerItem: WKPickerItem {
        let i = WKPickerItem()
        i.title = title
        return i
    }
    
}

