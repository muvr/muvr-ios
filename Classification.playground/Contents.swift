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
func model(named name: String, layerConfiguration: String, labels: [String]) throws -> MKExerciseModel {
    let demoModelPath = NSBundle.mainBundle().pathForResource(name, ofType: "raw")!
    let weights = MKExerciseModel.loadWeightsFromFile(demoModelPath)
    let model = MKExerciseModel(
        layerConfiguration: try MKLayerConfiguration.parse(text: layerConfiguration),
        weights: weights,
        sensorDataTypes: [.Accelerometer(location: .LeftWrist)],
        exerciseIds: labels,
        minimumDuration: 5)
    return model
}

//: ### Construct a classifier
let exerciseClassifier = try! MKClassifier(model: model(named: "arms_model.weights",
    layerConfiguration: "1200 id 250 relu 100 relu 3 logistic",
    labels: ["arms/biceps-curl", "arms/triceps-extension", "shoulders/lateral-raise"]))

let slackingClassifier = try! MKClassifier(model: model(named: "Nov12_slacking_model.weights",
    layerConfiguration: "1200 id 500 relu 100 relu 25 relu 2 logistic",
    labels: ["none", "exercise"]))
//: ### Load the data from the session
//let resourceName = "no-movement-face-up"
let resourceName = "bc-only"
let exerciseData = NSBundle.mainBundle().pathForResource(resourceName, ofType: "raw")!

let slackingData = try MKSensorData.initDataFromCSV(filename: "slacking_dataset", ext: "csv")
//: ### Decode the sensor data
let sd = try! MKSensorData(decoding: NSData(contentsOfFile: exerciseData)!)

let axis = 0
let window = 1
let windowSize = 400
(window * windowSize..<(window + 1) * windowSize).map { idx in  return sd.samples[idx * 3 + axis] }

//: ### Apply the classifier
// classify
//let cls = try! exerciseClassifier.classify(block: sd, maxResults: 10)
//cls.forEach { wcls in print(wcls) }

// test slacking dataset
print("EVALUATE SLACKING MODEL\n")
//let slk = try! slackingClassifier.classify(block: slackingData.sliceByCSVRow(from: 3303, to: 4440), maxResults: 2) // EXERCISE
//let slk = try! slackingClassifier.classify(block: slackingData.sliceByCSVRow(from: 9097, to: 9980), maxResults: 2) // EXERCISE
let slk = try! slackingClassifier.classify(block: slackingData.sliceByCSVRow(from: 12401, to: 13252), maxResults: 2) // EXERCISE
print("\n\nRESULT:")
slk.forEach { wcls in print(wcls) }


