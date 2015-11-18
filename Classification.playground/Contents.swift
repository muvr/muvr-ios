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
    let model = try MKExerciseModel(
        layerConfiguration: MKLayerConfiguration.parse(text: layerConfiguration),
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

let eneClassifier = try! MKClassifier(model: model(named: "slacking_model.weights",
    layerConfiguration: "1200 id 500 relu 100 relu 25 relu 2 logistic",
    labels: ["-", "E"]))

//: ### Load the data from the session
//let resourceName = "no-movement-face-up"
//let resourceName = "bc-only"
let resourceName = "arms_9F6F4AF0-F85B-4ACF-9E51-71717D141280"
let exerciseData = NSBundle.mainBundle().pathForResource(resourceName, ofType: "raw")!

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

func shiftOffset(offset: MKTimestamp)(x: MKClassifiedExercise) -> MKClassifiedExercise {
    return MKClassifiedExercise(confidence: x.confidence, exerciseId: x.exerciseId, duration: x.duration, offset: x.offset + offset, repetitions: x.repetitions, intensity: x.intensity, weight: x.weight)
}

func printCsv(data data: MKSensorData, windows: [MKClassifiedExerciseWindow]) {
    let stepsInWindow = 40
    let numWindows = windows.count
    (0..<numWindows + stepsInWindow).forEach { i in
        let minWindow = max(0, i - stepsInWindow)
        let maxWindow = min(i, numWindows - 1)
        var avg: [MKExerciseId:Double] = [:]
        (minWindow..<maxWindow + 1).forEach { w in
            let ws = Double(maxWindow - minWindow + 1)
            for block in windows[w].classifiedExerciseBlocks {
                let blockAvg = block.confidence / ws
                if let exAvg = avg[block.exerciseId] {
                    avg[block.exerciseId] = exAvg + blockAvg
                } else {
                    avg[block.exerciseId] = blockAvg
                }
            }
        }
        for j in i * 10...(i+1) * 10 - 1{
            let offset = j * 3
            if offset >= data.samples.count - 3 { break }
            let x = data.samples[offset]
            let y = data.samples[offset+1]
            let z = data.samples[offset+2]
            print("\(x),\(y),\(z),\(avg["-"]!),\(avg["E"]!)")
        }
    }
}

let windows = try eneClassifier.classifyWindows(block: sd, maxResults: 2)
let steps = eneClassifier.classifySteps(windows, samplesPerSecond: sd.samplesPerSecond)
printCsv(data: sd, windows: windows)
let results = try eneClassifier.classify(block: sd, maxResults: 2)
print("")
print("E/NE classification")
results.forEach { x in print(x) }
let cls = results.flatMap { result -> [MKClassifiedExercise] in
    if result.exerciseId == "E" && result.duration >= 8.0 {
        // this is an exercise block - get the corresponding data section
        let data = try! sd.slice(result.offset, duration: result.duration)
        // classify the exercises in this block
        let exercises = try! exerciseClassifier.classify(block: data, maxResults: 10)
        NSLog("Specific exercise \(results)")
        // adjust the offset with the offset from the original block
        // the offset returned by the classifier is relative to the current exercise block
        return exercises.map(shiftOffset(result.offset))
    } else {
        return []
    }
}
print("")
print("Exercise classification")
cls.forEach { wcls in print(wcls) }
