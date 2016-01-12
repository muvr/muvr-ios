import Foundation
import UIKit

class MRSessionLabellingViewController: UIViewController {
    
    @IBOutlet weak var repetitionsView: MRRepetitionsView!
    @IBOutlet weak var weightView: MRWeightView!
    @IBOutlet weak var intensityView: MRBarsView!
    
    var repetitions: Int? {
        return repetitionsView.value
    }
    
    var weight: Double? {
        return weightView.value
    }
    
    var intensity: Double {
        return Double(intensityView.value) / Double(intensityView.bars)
    }
    
    override func viewDidAppear(animated: Bool) {
        repetitionsView.value = 10
        intensityView.value = 3
        weightView.value = 5
    }
    
    
    @IBAction func decrementRepetitions() {
        if let value = repetitionsView.value where value > 0 {
            repetitionsView.value = value - 1
        }
    }
    
    @IBAction func incrementRepetitions() {
        if let value = repetitionsView.value {
            repetitionsView.value = value + 1
        }
    }
    
    @IBAction func decrementWeight() {
        if let value = weightView.value where value > 0.5 {
            weightView.value = value - 0.5
        }
    }
    
    @IBAction func incrementWeight() {
        if let value = weightView.value {
            weightView.value = value + 0.5
        }
    }
    
    @IBAction func decrementIntensity() {
        if intensityView.value  > 0 {
            intensityView.value -= 1
        }
    }
    
    @IBAction func incrementIntensity() {
        if intensityView.value < intensityView.bars {
            intensityView.value += 1
        }
    }
    
    
}
