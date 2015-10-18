//: # Whole-session classification
//: The core idea is to slide window over the input and watch the variation
//: of the classified data.
//: Our hypothesis is that there is some kind of probabilistic model that 
//: can identify exercise blocks given the classification result on each
//: window.
import UIKit
import XCPlayground
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
        minimumDuration: 8)
    return model
}

//: ### Construct a classifier
let classifier = MKClassifier(model: model(named: "demo"))

//: ### Load the data from the session
let exerciseData = NSBundle.mainBundle().pathForResource("bc-te-bc-bc-te", ofType: "raw")!

//: ### Decode the sensor data
let sd = try! MKSensorData(decoding: NSData(contentsOfFile: exerciseData)!)

//: ### Now run the sliding windows
// classify
let cls = try! classifier.classify(block: sd, maxResults: 10)
cls.forEach { wcls in print(wcls) }

