//: # Whole-session classification
//: The core idea is to slide window over the input and watch the variation
//: of the classified data.
//: Our hypothesis is that there is some kind of probabilistic model that 
//: can identify exercise blocks given the classification result on each
//: window.
import UIKit
import XCPlayground
import Accelerate
@testable import MuvrKit

extension MKClassifiedExerciseWindow {
    var time: Double {
        return Double(window) * 0.2
    }
}
//: ### Helper functions
func model(named name: String, layerConfig: [Int], labels: [String]) -> MKExerciseModel {
    let demoModelPath = NSBundle.mainBundle().pathForResource(name, ofType: "raw")!
    let weights = MKExerciseModel.loadWeightsFromFile(demoModelPath)
    let model = MKExerciseModel(layerConfig: layerConfig, weights: weights,
        sensorDataTypes: [.Accelerometer(location: .LeftWrist)],
        exerciseIds: labels,
        minimumDuration: 5)
    return model
}

//: ### Construct a classifier
let exerciseClassifier = try MKClassifier(model: model(named: "demo", layerConfig: [1200, 250, 100, 3], labels: ["biceps-curl", "lateral-raise", "triceps-extension"]))
let activityClassifier = try MKClassifier(model: model(named: "activity", layerConfig: [1200, 500, 100, 25, 2], labels: ["E", "-"]))

//: ### Load the data from the session
//let resourceName = "no-movement-face-up"
let resourceName = "bc-only"
let exerciseData = NSBundle.mainBundle().pathForResource(resourceName, ofType: "raw")!

//: ### Decode the sensor data
let sd = try! MKSensorData(decoding: NSData(contentsOfFile: exerciseData)!)

let axis = 0
let window = 1
let windowSize = 400
(window * windowSize..<(window + 1) * windowSize).map { idx in  return sd.samples[idx * 3 + axis] }

//: ### Apply the classifier
// classify
let cls = try! exerciseClassifier.classify(block: sd, maxResults: 10)
let en = try! activityClassifier.classify(block: sd, maxResults: 2)
en.forEach { wcls in print(wcls) }
cls.forEach { wcls in print(wcls) }

var floats = [Float](count: 40, repeatedValue: 2)
var len = Int32(floats.count)
var x: UnsafeMutablePointer<Float> = UnsafeMutablePointer(floats)
vvexpf(x, x, &len)

floats


