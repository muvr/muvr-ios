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

extension MKSensorData {
    public static func initDataFromCSV(filename filename: String, ext: String) throws -> MKSensorData {
        func loadTextFiles(filename filename: String, ext: String, separator: NSCharacterSet) -> [String] {
            let fullPath = NSBundle.mainBundle().pathForResource(filename, ofType: ext)!
            func removeEmptyStr(arrStr: [String]) -> [String] {
                return arrStr
                    .filter {$0 != ""}
                    .map {$0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())}
            }
            do {
                let content = try String(contentsOfFile: fullPath, encoding: NSUTF8StringEncoding)
                return removeEmptyStr(content.componentsSeparatedByCharactersInSet(separator))
            } catch {
                return []
            }
        }
        
        let csvArr = loadTextFiles(filename: filename, ext: ext, separator: NSCharacterSet.newlineCharacterSet())
        let samples = csvArr.flatMap { line -> [Float] in
            let split = line.componentsSeparatedByString(",")
            let X = NSString(string: split[0]).floatValue
            let Y = NSString(string: split[1]).floatValue
            let Z = NSString(string: split[2]).floatValue
            return [X, Y, Z]
        }
        let types = [MKSensorDataType.Accelerometer(location: MKSensorDataType.Location.LeftWrist)]
        return try MKSensorData(types: types, start: 0, samplesPerSecond: UInt(50), samples: samples)
    }
    
    public func sliceByCSVRow(from from: Int, to: Int) throws -> MKSensorData {
        let sampleStart = dimension * (from - 1)
        let sampleEnd = dimension * to
        let data = samples[sampleStart..<sampleEnd]
        return try MKSensorData(types: types, start: start, samplesPerSecond: samplesPerSecond, samples: Array(data))
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
    layerConfiguration: "1200 id 250 relu 50 relu 3 logistic",
    labels: ["shoulders/lateral-raise", "arms/biceps-curl", "arms/triceps-extension"]))


let slackingClassifier = try! MKClassifier(model: model(named: "Nov12_slacking_model.weights",
    layerConfiguration: "1200 id 500 relu 100 relu 25 relu 2 logistic",
    labels: ["none", "exercise"]))

let eneClassifier = try! MKClassifier(model: model(named: "slacking_model.weights",
    layerConfiguration: "1200 id 250 relu 50 relu 2 logistic",
    labels: ["-", "E"]))


//: ### Load the data from the session
//let resourceName = "no-movement-face-up"
//let resourceName = "bc-only"
//let resourceName = "arms_9F6F4AF0-F85B-4ACF-9E51-71717D141280"
//let resourceName = "arms_AA86976B-F6CA-4A9B-B786-469171D6D341"
//let resourceName = "arms_05D8C7FE-7D92-4F5A-9CCB-45B7D3799283"
let resourceName = "arms_AA32C720-B574-413E-A4AA-E741DA16ABF5"
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
print("END\n")

func shiftOffset(offset: MKTimestamp)(x: MKClassifiedExercise) -> MKClassifiedExercise {
    return MKClassifiedExercise(confidence: x.confidence, exerciseId: x.exerciseId, duration: x.duration, offset: x.offset + offset, repetitions: x.repetitions, intensity: x.intensity, weight: x.weight)
}

func printCsv(data data: MKSensorData, windows: [MKClassifiedExerciseWindow], exerciseWindows: [MKClassifiedExerciseWindow?]) {
    
    let file = "classification-\(resourceName).csv"
    let documentsUrl = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first!
    let fileUrl = NSURL(fileURLWithPath: documentsUrl).URLByAppendingPathComponent(file)
    do { try NSFileManager.defaultManager().removeItemAtURL(fileUrl) } catch { /*don't care*/ }
    try! "".writeToURL(fileUrl, atomically: true, encoding: NSASCIIStringEncoding)
    let handle = try! NSFileHandle(forWritingToURL: fileUrl)
    
    print("Generating CSV file in \(fileUrl)")
    
    let stepsInWindow = 40
    let numWindows = windows.count
    (0..<numWindows + stepsInWindow).forEach { i in
        let minWindow = max(0, i - stepsInWindow)
        let maxWindow = min(i, numWindows - 1)
        let ws = Double(maxWindow - minWindow + 1)
        var avg: [MKExerciseId:Double] = [:]
        (minWindow..<maxWindow + 1).forEach { w in
            for block in windows[w].classifiedExerciseBlocks {
                let blockAvg = block.confidence / ws
                if let exAvg = avg[block.exerciseId] {
                    avg[block.exerciseId] = exAvg + blockAvg
                } else {
                    avg[block.exerciseId] = blockAvg
                }
            }
            if let exWind = exerciseWindows[w] {
                for block in exWind.classifiedExerciseBlocks {
                    let blockAvg = block.confidence / ws
                    if let exAvg = avg[block.exerciseId] {
                        avg[block.exerciseId] = exAvg + blockAvg
                    } else {
                        avg[block.exerciseId] = blockAvg
                    }
                }
            }
        }
        for j in i * 10...(i+1) * 10 - 1{
            let offset = j * 3
            if offset >= data.samples.count - 3 { break }
            let x = data.samples[offset]
            let y = data.samples[offset+1]
            let z = data.samples[offset+2]
            var ex = 0
            if let ne = avg["-"], let e = avg["E"] where e > ne {
                ex = 1
            }
            var bc = 0
            var te = 0
            var lr = 0
            if let pbc = avg["arms/biceps-curl"], let pte = avg["arms/triceps-extension"], let plr = avg["shoulders/lateral-raise"] {
                if (pbc > pte && pbc > plr) { bc = 1 }
                if (pte > pbc && pte > plr) { te = 1 }
                if (plr > pbc && plr > pte) { lr = 1 }
            }
            if let row = "\(x),\(y),\(z),\(avg["-"]!),\(avg["E"]!),\(ex),\(avg["arms/biceps-curl"] ?? 0.0),\(avg["arms/triceps-extension"] ?? 0.0),\(avg["shoulders/lateral-raise"] ?? 0.0),\(bc),\(te),\(lr)\n".dataUsingEncoding(NSASCIIStringEncoding) {
                handle.writeData(row)
            }
        }
    }
    handle.closeFile()
    print("CSV ready")
}

let windows = try! eneClassifier.classifyWindows(block: sd, maxResults: 2)
let results = try! eneClassifier.classify(block: sd, maxResults: 2)
print("")
print("E/NE classification")
results.forEach { x in print(x) }
var exerciseWindows = [MKClassifiedExerciseWindow?](count: windows.count, repeatedValue: nil)
let cls = results.flatMap { result -> [MKClassifiedExercise] in
    if result.exerciseId == "E" && result.duration >= 8.0 {
        // this is an exercise block - get the corresponding data section
        let data = try! sd.slice(result.offset, duration: result.duration)
        // classify the exercises in this block
        let exercises = try! exerciseClassifier.classify(block: data, maxResults: 10)
        let exWindows = try! exerciseClassifier.classifyWindows(block: data, maxResults: 10)
        for i in 0...exWindows.count-1 {
            exerciseWindows[i + Int(result.offset * 5)] = exWindows[i]
        }
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

printCsv(data: sd, windows: windows, exerciseWindows: exerciseWindows)
