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
let windowSize = 50
(0..<900).forEach { wi in
    let windowSamples = sd.samples(along: [.Accelerometer(location: .LeftWrist)], range: Range<Int>(start: windowSize * wi, end: windowSize * wi + 400)).1

    // display window data
    // windowSamples.enumerate().forEach { i, x in if i % 3 == 0 { x } }

    // compute the window
    let window = try! MKSensorData(types: sd.types, start: sd.start, samplesPerSecond: sd.samplesPerSecond, samples: windowSamples)
    
    // classify
    let windowClassification = try! classifier.classify(block: window, maxResults: 10)
    windowClassification.first.map { x in print(x) }
}

