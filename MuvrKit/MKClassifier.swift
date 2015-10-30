import Foundation
import Accelerate
import MLPNeuralNet

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
    private let neuralNet: MLPNeuralNet
    private let windowSize = 400
    private let windowStepSize = 10
    private let numInputs: Int
    private let numClasses: Int
    
    ///
    /// Initializes the classifier given the ``model``.
    ///
    /// - parameter model: the model
    ///
    public init(model: MKExerciseModel) {
        self.model = model
        self.neuralNet = MLPNeuralNet(layerConfig: model.layerConfig, weights: model.weights, outputMode: MLPClassification)
        self.neuralNet.hiddenActivationFunction = MLPReLU
        self.neuralNet.outputActivationFunction = MLPSigmoid
        
        self.numInputs = self.model.layerConfig.first!
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
        // in the outer function, we perform the common decoding and basic checking
        let (dimension, m) = block.samples(along: model.sensorDataTypes)
        if dimension == 0 {
            // we could not find any slice that the model requires
            throw MKClassifierError.NoSensorDataType(received: block.types, required: model.sensorDataTypes)
        }
        
        let rowCount = m.count / dimension
        if rowCount < windowSize {
            // not enough input for classification
            throw MKClassifierError.NotEnoughRows(received: block.rowCount, required: windowSize)
        }

        // TODO: Use vDSP_vspdp
        var doubleM = m.map { Double($0) }
        let numWindows = (rowCount - windowSize) / windowStepSize + 1
                
        let cews: [MKClassifiedExerciseWindow] = (0..<numWindows).map { window in
            let offset = dimension * windowStepSize * window * sizeof(Double)
            
            // NSLog("bytes \(offset)-\(offset + windowSize * sizeof(Double)); length \(doubleM.count * sizeof(Double))")

            let featureMatrix = NSData(bytes: &doubleM + offset, length: dimension * windowSize * sizeof(Double))
            let windowPrediction = NSMutableData(length: numClasses * sizeof(Double))!
            neuralNet.predictByFeatureMatrix(featureMatrix, intoPredictionMatrix: windowPrediction)
            let probabilities = UnsafePointer<Double>(windowPrediction.bytes)
            let classRanking = (0..<numClasses).sort { x, y in
                return probabilities[x] > probabilities[y]
            }
            let resultCount = min(maxResults, numClasses)
            let classifiedExerciseBlocks: [MKClassifiedExerciseBlock] = (0..<resultCount).flatMap { i in
                let labelIndex = classRanking[i]
                
                let labelName = self.model.exerciseIds[labelIndex]
                let probability = probabilities[labelIndex]
                if probability > 0.7 {
                    let duration = Double(windowStepSize) / Double(block.samplesPerSecond)
                    return MKClassifiedExerciseBlock(confidence: probability, exerciseId: labelName, duration: duration, offset: duration * Double(window))
                }
                return nil
            }
            return MKClassifiedExerciseWindow(window: window, classifiedExerciseBlocks: classifiedExerciseBlocks)
        }
        
        if cews.isEmpty { return [] }
        
        var result: [MKClassifiedExerciseBlock] = []
        var accumulator: MKClassifiedExerciseBlock? = nil
        for var i = 0; i < cews.count; ++i {
            let cew = cews[i]
            NSLog("\(cew.window) -> \(cews[i].classifiedExerciseBlocks.first)")
            if let current = cews[i].classifiedExerciseBlocks.first {
                if accumulator == nil {
                    accumulator = current
                } else if current.isRoughlyEqual(accumulator!) {
                    accumulator!.extend(current)
                } else {
                    result.append(accumulator!)
                    accumulator = current
                }
            } else {
                if let a = accumulator { result.append(a) }
                accumulator = nil
            }
        }
        if let a = accumulator { result.append(a) }
        
        return result.filter { $0.duration >= self.model.minimumDuration }.map { x in
            return MKClassifiedExercise(confidence: x.confidence, exerciseId: x.exerciseId, duration: x.duration, offset: x.offset, repetitions: nil, intensity: nil, weight: nil)
        }
    }    
}

struct MKClassifiedExerciseBlock {
    var confidence: Double
    let exerciseId: MKExerciseId
    var duration: MKTimestamp
    let offset: MKTimestamp
    private var blocks: Double // counts the number of single blocks accumulated into this block
    
    mutating func extend(by: MKClassifiedExerciseBlock) {
        // the new confidence the average confidence of both blocks
        self.confidence = (self.confidence * self.blocks + by.confidence * by.blocks) / (self.blocks + by.blocks)
        self.duration = self.duration + by.duration
        self.blocks = self.blocks + by.blocks
    }

    func isRoughlyEqual(to: MKClassifiedExerciseBlock) -> Bool {
        return self.exerciseId == to.exerciseId && abs(self.confidence - to.confidence) < 0.1
    }
    
    init(confidence: Double, exerciseId: MKExerciseId, duration: MKTimestamp, offset: MKTimestamp) {
        self.confidence = confidence
        self.exerciseId = exerciseId
        self.duration = duration
        self.offset = offset
        self.blocks = 1.0
    }
}


struct MKClassifiedExerciseWindow {
    let window: Int
    let classifiedExerciseBlocks: [MKClassifiedExerciseBlock]
}
