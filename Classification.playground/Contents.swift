//: # Whole-session classification
//: The core idea is to slide window over the input and watch the variation
//: of the classified data.
//: Our hypothesis is that there is some kind of probabilistic model that 
//: can identify exercise blocks given the classification result on each
//: window.
import UIKit
import XCPlayground
@testable import MuvrKit

//: ### Helper functions
func model(named name: String) -> MKExerciseModel {
    let demoModelPath = NSBundle.mainBundle().pathForResource(name, ofType: "raw")!
    let weightsData = NSData(contentsOfFile: demoModelPath)!
    let model = MKExerciseModel(layerConfig: [1200, 250, 100, 3], weights: weightsData,
        sensorDataTypes: [.Accelerometer(location: .LeftWrist)],
        exerciseIds: ["biceps-curl", "triceps-extension", "lateral-raise"])
    return model
}

//: ### Construct a classifier
let classifier = MKClassifier(model: model(named: "demo"))

//: ### Load the data from the session
let mostlyExerciseData = NSBundle.mainBundle().pathForResource("mostly-exercise", ofType: "raw")!

//: ### Decode the sensor data
let sd = try! MKSensorData(decoding: NSData(contentsOfFile: mostlyExerciseData)!)

//: ### Now run the sliding windows
// classify
let cls = try! classifier.classify(block: sd, maxResults: 10)
cls.forEach { wcls in print("\(wcls.window): \(wcls.classifiedExercises.first)") }

