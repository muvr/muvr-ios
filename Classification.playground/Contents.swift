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
func model(named name: String) -> MKExerciseModel {
    let demoModelPath = NSBundle.mainBundle().pathForResource(name, ofType: "raw")!
    let weightsData = NSData(contentsOfFile: demoModelPath)!
    let model = MKExerciseModel(layerConfig: [1200, 250, 100, 3], weights: weightsData,
        sensorDataTypes: [.Accelerometer(location: .LeftWrist)],
        exerciseIds: ["biceps-curl", "lateral-raise", "triceps-extension"],
        minimumDuration: 5)
    return model
}

//: ### Construct a classifier
let classifier = MKClassifier(model: model(named: "demo"))

//: ### Load the data from the session
let resourceName = "no-movement-face-up"
//let resourceName = "bc-te-bc-bc-te"
let exerciseData = NSBundle.mainBundle().pathForResource(resourceName, ofType: "raw")!

//: ### Decode the sensor data
let sd = try! MKSensorData(decoding: NSData(contentsOfFile: exerciseData)!)

let axis = 2
let window = 8
let windowSize = 400
(window * windowSize..<(window + 1) * windowSize).map { idx in  return sd.samples[idx * 3 + axis] }
var mean: Float = 0
var samples: [Float] = sd.samples
let N = vDSP_Length(samples.count / 3)
vDSP_measqv(&samples + axis, 3, &mean, N)

mean
//: ### Now run the sliding windows
// classify
let cls = try! classifier.classify(block: sd, maxResults: 10)
cls.forEach { wcls in print(wcls) }

