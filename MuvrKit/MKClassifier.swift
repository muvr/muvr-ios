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
    case NoSensorDataType(required: [MKSensorDataType])
    
    ///
    /// The sensor data does not contain enough data for the classification
    ///
    /// - parameter required: the required number of rows
    ///
    case NotEnoughRows(required: Int)
}

///
/// Classifies the input data according to the model
///
struct MKClassifier {
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
    init(model: MKExerciseModel) {
        self.model = model
        self.neuralNet = MLPNeuralNet(layerConfig: model.layerConfig, weights: model.weights, outputMode: MLPClassification)
        self.neuralNet.hiddenActivationFunction = MLPReLU
        self.neuralNet.outputActivationFunction = MLPSigmoid
        
        self.numInputs = self.model.layerConfig.first!
        self.numClasses = self.model.exerciseIds.count
    }
    
    private func featureMatrixFrom(inputData: [Double], dimension: Int, numWindows: Int) -> NSData {
        let featureMatrix = NSMutableData(length: numInputs * numWindows * sizeof(Double))!
        
        for i in 0..<numWindows {
            let start  = i * windowStepSize * dimension
            let end    = i * windowStepSize + windowSize * dimension
            var window = Array(inputData[start..<end])
            #if false
            cblas_dscal(Int32(window.count), 1 / 4000, &window, 1)
            #endif
            
            featureMatrix.appendBytes(&window, length: window.count * sizeof(Double))
        }
        
        return featureMatrix
    }
    
    private func calculateClassProbabilities(predictions: UnsafePointer<Double>, numWindows: Int) -> [Double] {
        return (0..<numClasses).map { cls in
            var sumForClass: Double = 0
            for w in 0..<numWindows {
                sumForClass += predictions[cls * numWindows + w]
            }
            return sumForClass
        }
    }
    
    ///
    /// Classifies the data in the ``block``, returning up to ``maxResults`` results. The classifier will
    /// take an appropriate slice of the data from the given block; ideally, the slice is the exact data set.
    /// This is driven by the model, and so it is important to ensure that the right instance of the classifier
    /// is used to do the classification.
    ///
    /// - parameter block: the received sensor data
    ///
    func classify(block block: MKSensorData, maxResults: Int) throws -> [MKClassifiedExercise] {
        let (dimension, m) = block.samples(along: model.sensorDataTypes)
        if dimension == 0 {
            // we could not find any slice that the model requires
            throw MKClassifierError.NoSensorDataType(required: model.sensorDataTypes)
        }
        
        let rowCount = m.count / dimension
        if (rowCount < windowSize) {
            // not enough input for classification
            throw MKClassifierError.NotEnoughRows(required: windowSize)
        }
        
        let doubleM = m.map { Double($0) }
        let numWindows = (rowCount - windowSize) / windowStepSize + 1

        let featureMatrix = featureMatrixFrom(doubleM, dimension: dimension, numWindows: numWindows)
        let windowPrediction = NSMutableData(length: numClasses * numWindows * sizeof(Double))!
        neuralNet.predictByFeatureMatrix(featureMatrix, intoPredictionMatrix: windowPrediction)
        let probabilities = calculateClassProbabilities(UnsafePointer<Double>(windowPrediction.bytes), numWindows: numWindows)
        let classRanking = (0..<numClasses).sort { x, y in
            return probabilities[x] > probabilities[y]
        }
        let resultCount = min(maxResults, numClasses)
        return (0..<resultCount).map { i in
            let labelIndex = classRanking[i]
            
            let labelName = self.model.exerciseIds[labelIndex]
            let probability = probabilities[labelIndex]
            return MKClassifiedExercise.Resistance(confidence: probability, exerciseId: labelName, duration: block.duration, repetitions: nil, intensity: nil, weight: nil)
            
        }
    }
    
}
