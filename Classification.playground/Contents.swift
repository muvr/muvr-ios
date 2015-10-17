//: # Whole-session classification
//: The core idea is to slide window over the input and watch the variation
//: of the classified data

import UIKit
import XCPlayground
@testable import MuvrKit

//: ### Helper functions
func model(named name: String) -> MKExerciseModel {
    let demoModelPath = NSBundle.mainBundle().pathForResource(name, ofType: "raw")!
    let weightsData = NSData(contentsOfFile: demoModelPath)!
    let model = MKExerciseModel(layerConfig: [1200, 250, 100, 3], weights: weightsData,
        sensorDataTypes: [.Accelerometer(location: .LeftWrist)],
        exerciseIds: ["1", "2", "3"])
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
(0..<100).forEach { wi in
    let windowSamples = sd.samples(along: [.Accelerometer(location: .LeftWrist)], range: Range<Int>(start: windowSize * wi, end: windowSize * wi + 400)).1

    // display window data
    windowSamples.enumerate().forEach { i, x in if i % 3 == 0 { x } }

    // compute the window
    let window = try! MKSensorData(types: sd.types, start: sd.start, samplesPerSecond: sd.samplesPerSecond, samples: windowSamples)
    
    // classify
    let windowClassification = try! classifier.classify(block: window, maxResults: 10)
    print("-------------")
    windowClassification.forEach { x in print(x) }
}

