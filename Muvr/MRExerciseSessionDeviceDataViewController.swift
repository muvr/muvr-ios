import UIKit
//import Charts

///
/// Controls a view in ``Exercise.storyboard``, which displays a chart with the recorded sensor data and the current
/// state of the movement and exercise deciders.
///
class MRExerciseSessionDeviceDataViewController: UIViewController, MRExerciseBlockDelegate, MRDeviceDataDelegate {
    static let storyboardId: String = "MRExerciseSessionDeviceDataViewController"
    
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var exerciseLabel: UILabel!
    var sensorView: MRSensorView!
            
    // MARK: MRExerciseBlockDelegate implementation
    func exerciseEnded() {
        statusLabel.text = "Exercise ended";
    }
    
    func exercising() {
        statusLabel.text = "Exercising";
    }
    
    func moving() {
        statusLabel.text = "Moving";
    }
    
    func notMoving() {
        statusLabel.text = "Not moving";
    }

    // MARK: MRDeviceDataDelegate implementation
    func deviceDataDecoded1D(rows: [AnyObject]!, fromSensor sensor: UInt8, device deviceId: UInt8, andLocation location: UInt8) {
        sensorView.deviceDataDecoded1D(rows, fromSensor: sensor, device: deviceId, andLocation: location)
    }
    
    func deviceDataDecoded3D(rows: [AnyObject]!, fromSensor sensor: UInt8, device deviceId: UInt8, andLocation location: UInt8) {
        sensorView.deviceDataDecoded3D(rows, fromSensor: sensor, device: deviceId, andLocation: location)
    }
    
}
