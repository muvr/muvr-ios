import Foundation
import Accelerate
import MLPNeuralNet

///
/// Possible classification errors
///
enum MKClassifierError : ErrorType {
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

public struct MKClassifiedExerciseWindow {
    public let window: Int
    public let classifiedExercises: [MKClassifiedExercise]
    
    public init(window: Int, classifiedExercises: [MKClassifiedExercise]) {
        self.window = window
        self.classifiedExercises = classifiedExercises
    }
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
    public func classify(block block: MKSensorData, maxResults: Int) throws -> [MKClassifiedExerciseWindow] {
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

        var doubleM = m.map { Double($0) }
        let numWindows = (rowCount - windowSize) / windowStepSize + 1
        
        return (0..<numWindows).map { window in
            let offset = windowSize * window
            let featureMatrix = NSData(bytes: &doubleM + offset, length: dimension * windowSize * sizeof(Double))
            let windowPrediction = NSMutableData(length: numClasses * sizeof(Double))!
            neuralNet.predictByFeatureMatrix(featureMatrix, intoPredictionMatrix: windowPrediction)
            let probabilities = UnsafePointer<Double>(windowPrediction.bytes)
            let classRanking = (0..<numClasses).sort { x, y in
                return probabilities[x] > probabilities[y]
            }
            let resultCount = min(maxResults, numClasses)
            let classifiedExercises = (0..<resultCount).flatMap { (i: Int) -> MKClassifiedExercise? in
                let labelIndex = classRanking[i]
                
                let labelName = self.model.exerciseIds[labelIndex]
                let probability = probabilities[labelIndex]
                if probability > 0.7 {
                    return MKClassifiedExercise.Resistance(confidence: probability, exerciseId: labelName, duration: 0, repetitions: nil, intensity: nil, weight: nil)
                }
                
                return nil
            }
            return MKClassifiedExerciseWindow(window: window, classifiedExercises: classifiedExercises)
        }
    }    
}
