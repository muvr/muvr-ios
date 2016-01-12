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
    
    enum State {
        case Idle
        case IntensityChanged(inc: Int)
        case WeightChanged(inc: Double)
        case RepetitionsChanged(inc: Int)
    }
    
    var state: State = .Idle
    var timer: NSTimer? = nil
    
    override func viewDidAppear(animated: Bool) {
        repetitionsView.value = 10
        intensityView.value = 3
        weightView.value = 5
    }
    
    
    @IBAction func startIncRepetitions() {
        state = .RepetitionsChanged(inc: 1)
        startTimer()
    }
    
    @IBAction func startIncWeight() {
        state = .WeightChanged(inc: 0.5)
        startTimer()
    }
    
    @IBAction func startIncIntensity() {
        state = .IntensityChanged(inc: 1)
        startTimer()
    }
    
    @IBAction func startDecRepetitions() {
        state = .RepetitionsChanged(inc: -1)
        startTimer()
    }
    
    @IBAction func startDecWeight() {
        state = .WeightChanged(inc: -0.5)
        startTimer()
    }
    
    @IBAction func startDecIntensity() {
        state = .IntensityChanged(inc: -1)
        startTimer()
    }
    
    private func startTimer() {
        refresh()
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(0.15, target: self, selector: "refresh", userInfo: nil, repeats: true)
        }
    }
    
    internal func refresh() {
        switch state {
        case .IntensityChanged(let inc):
            intensityView.value += inc
        case .WeightChanged(let inc):
            if let value = weightView.value {
                weightView.value = value + inc
            }
            if abs(inc) < 1 {
                state = .WeightChanged(inc: inc * 2)
            }
        case .RepetitionsChanged(let inc):
            if let value = repetitionsView.value {
                repetitionsView.value = value + inc
            }
        case .Idle: return
        }
    }
    
    @IBAction func stopTimer() {
        state = .Idle
        timer?.invalidate()
        timer = nil
    }
    
}
