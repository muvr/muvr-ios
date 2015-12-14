import Foundation
import Accelerate

///
/// Possible classification errors
///
public enum MKClassifierError : ErrorType {
    ///
    /// The sensor data does not contain any of the required sensor data types
    ///
    /// - parameter required: the required types
    ///
    case NoSensorDataType(received: [MKSensorDataType], required: [MKSensorDataType])
    
    ///
    /// The sensor data does not contain enough data for the classification
    ///
    /// - parameter required: the required number of rows
    ///
    case NotEnoughRows(received: Int, required: Int)
}

///
/// Classifies the input data according to the model
///
public struct MKClassifier {
    private let model: MKExerciseModel
    private let neuralNet: MKForwardPropagator
    private let inputPreperator: MKInputPreperator
    private let windowSize = 400
    private let windowStepSize = 10
    private let numInputs: Int
    private let numClasses: Int
    
    ///
    /// Initializes the classifier given the ``model``.
    ///
    /// - parameter model: the model
    ///
    public init(model: MKExerciseModel) throws {
        self.model = model
        let netConfig = MKForwardPropagatorConfiguration(
            layerConfiguration: model.layerConfiguration,
            biasValue: 1.0,
            biasUnits: 1)
        self.neuralNet = try MKForwardPropagator.configured(netConfig, weights: model.weights)
        self.inputPreperator = MKInputPreperator()
        self.numInputs = self.model.layerConfiguration.first!.size
        self.numClasses = self.model.exerciseIds.count
    }
    
    ///
    /// Classifies the data in the ``block``, returning up to ``maxResults`` results. The classifier will
    /// take an appropriate slice of the data from the given block; ideally, the slice is the exact data set.
    /// This is driven by the model, and so it is important to ensure that the right instance of the classifier
    /// is used to do the classification.
    ///
    /// - parameter block: the received sensor data
    ///
    public func classify(block block: MKSensorData, maxResults: Int) throws -> [MKClassifiedExercise] {
        let cews = try classifyWindows(block: block, maxResults: maxResults)
        if cews.isEmpty { return [] }
        let steps = classifySteps(cews, samplesPerSecond: block.samplesPerSecond)
        let exercises = accumulateSteps(steps)
        return fusionBlocks(exercises, samplesPerSecond: block.samplesPerSecond).map { x in
            return MKClassifiedExercise(confidence: x.confidence, exerciseId: x.exerciseId, duration: x.duration, offset: x.offset, repetitions: nil, intensity: nil, weight: nil)
        }
    }
    
    ///
    /// Apply the classification model to every window contained in ``block``
    ///
    func classifyWindows(block block: MKSensorData, maxResults: Int) throws -> [MKClassifiedExerciseWindow] {
        // in the outer function, we perform the common decoding and basic checking
        var (dimension, m) = block.samples(along: model.sensorDataTypes)
        if dimension == 0 {
            // we could not find any slice that the model requires
            throw MKClassifierError.NoSensorDataType(received: block.types, required: model.sensorDataTypes)
        }
        
        m = self.inputPreperator.preprocess(m)
        
        let rowCount = m.count / dimension
        if rowCount < windowSize {
            // not enough input for classification
            throw MKClassifierError.NotEnoughRows(received: block.rowCount, required: windowSize)
        }
        NSLog("Classification called for \(rowCount) samples (\(rowCount / 50)s)")
        
        let numWindows = (rowCount - windowSize) / windowStepSize + 1
        let duration = Double(windowStepSize) / Double(block.samplesPerSecond)
        
        let cews: [MKClassifiedExerciseWindow] = try (0..<numWindows).map { window in
            let offset = dimension * windowStepSize * window
            // NSLog("bytes \(offset)-\(offset + windowSize * sizeof(Double)); length \(doubleM.count * sizeof(Double))")
            let featureMatrix: UnsafePointer<Float> = UnsafePointer(m).advancedBy(offset)
            let windowPrediction = try neuralNet.predictFeatureMatrix(featureMatrix, length: dimension * windowSize)
            let classRanking = (0..<numClasses).sort { x, y in
                return windowPrediction[x] > windowPrediction[y]
            }
            let resultCount = min(maxResults, numClasses)
            let start = duration * Double(window)
            let classifiedExerciseBlocks: [MKClassifiedExerciseBlock] = (0..<resultCount).flatMap { i in
                let labelIndex = classRanking[i]
                
                let labelName = self.model.exerciseIds[labelIndex]
                let probability = windowPrediction[labelIndex]
                
                let windowDuration = window == numWindows - 1 ? (Double(windowSize) / Double(block.samplesPerSecond)) : duration
                return MKClassifiedExerciseBlock(confidence: Double(probability), exerciseId: labelName, duration: windowDuration, offset: start)
            }
            return MKClassifiedExerciseWindow(window: window, classifiedExerciseBlocks: classifiedExerciseBlocks)
        }
        return cews
    }
    
    ///
    /// Compute the probability for every window step by averaging the probabilities over all windows containing the step
    ///
    func classifySteps(windows: [MKClassifiedExerciseWindow], samplesPerSecond: UInt) -> [MKClassifiedExerciseBlock] {
        let duration = Double(windowStepSize) / Double(samplesPerSecond)
        let stepsInWindow = Int(windowSize / windowStepSize)
        let numWindows = windows.count
        let steps: [MKClassifiedExerciseBlock] = (0..<numWindows + stepsInWindow).flatMap { i in
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
            }
            let exIds = avg.keys.sort { id1, id2 in
                return avg[id1] > avg[id2]
            }
            if let exId = exIds.first {
                return MKClassifiedExerciseBlock(confidence: Double(avg[exId]!), exerciseId: exId, duration: duration, offset: Double(i) * duration )
            } else {
                return nil
            }
        }
        return steps
    }
    
    ///
    /// Group together consecutive steps with the same outcome
    ///
    func accumulateSteps(steps: [MKClassifiedExerciseBlock]) -> [MKClassifiedExerciseBlock] {
        var result: [MKClassifiedExerciseBlock] = []
        var accumulator: MKClassifiedExerciseBlock? = nil
        for var i = 0; i < steps.count; ++i {
            let current = steps[i]
            if accumulator == nil {
                accumulator = current
            } else if current.exerciseId == accumulator!.exerciseId {
                accumulator!.extend(current)
            } else {
                result.append(accumulator!)
                accumulator = current
            }
        }
        if let a = accumulator { result.append(a) }
        
        NSLog("classified \(result)")
        
        return result
    }
    
    /// 
    /// fusion adjacent blocks separated by a 'short' block
    ///
    func fusionBlocks(blocks: [MKClassifiedExerciseBlock], samplesPerSecond: UInt) -> [MKClassifiedExerciseBlock] {
        let windowDuration = Double(windowSize) / Double(samplesPerSecond)
        
        func isLongEnough(block: MKClassifiedExerciseBlock?) -> Bool {
            if let duration = block?.duration {
                return duration > windowDuration            }
            return true
        }
        func isSameExercise(block1: MKClassifiedExerciseBlock?, _ block2: MKClassifiedExerciseBlock?) -> Bool {
            if let block1 = block1, let block2 = block2 {
                return block1.exerciseId == block2.exerciseId
            }
            return false
        }
        func canMergeWith(block1: MKClassifiedExerciseBlock?, _ block2: MKClassifiedExerciseBlock?) -> Bool {
            if let block1 = block1, let block2 = block2 {
                return isSameExercise(block1, block2)
            }
            return isLongEnough(block1) || isLongEnough(block2)
        }
        
        var mergedBlocks: [MKClassifiedExerciseBlock] = []
        for var i = 0; i < blocks.count; i++ {
            let currentBlock = blocks[i]
            let prevBlock: MKClassifiedExerciseBlock? = mergedBlocks.last
            let nextBlock: MKClassifiedExerciseBlock? = i < blocks.count - 1 ? blocks[i + 1] : nil
        
            var block = currentBlock
            if !isLongEnough(currentBlock) && canMergeWith(prevBlock, nextBlock) || isSameExercise(prevBlock, currentBlock) {
                if let prevBlock = prevBlock {
                    block = prevBlock
                    mergedBlocks.removeLast()
                    block.extend(currentBlock)
                }
            }
            mergedBlocks.append(block)
        }
        
        return mergedBlocks
    }
}

struct MKClassifiedExerciseBlock {
    var confidence: Double
    let exerciseId: MKExerciseId
    var duration: MKTimestamp
    let offset: MKTimestamp
    
    mutating func extend(by: MKClassifiedExerciseBlock) {
        // the new confidence the average confidence of both blocks 
        // use the duration to apply correct weights in average computation
        let conf = self.exerciseId == by.exerciseId ? by.confidence : 0.0
        self.confidence = (self.confidence * self.duration + conf * by.duration) / (self.duration + by.duration)
        self.duration = round(100 * self.duration + 100 * by.duration) / 100
    }
}


struct MKClassifiedExerciseWindow {
    let window: Int
    let classifiedExerciseBlocks: [MKClassifiedExerciseBlock]
}
