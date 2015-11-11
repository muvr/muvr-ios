import Foundation
import Accelerate

struct MKForwardPropagatorLayer{
    let rowCount: Int
    let columnCount: Int
    let weights: [Float]
    let activationFunction: MKActivationFunction
}

///
/// Defines the activation layer
///
public struct MKLayerConfiguration {
    let size: Int
    let activationFunction: MKActivationFunction

    ///
    /// Initializes the layer configuration
    ///
    public init(size: Int, activationFunction: MKActivationFunction) {
        self.size = size
        self.activationFunction = activationFunction
    }
}

public struct MKForwardPropagatorConfiguration {
    /// Configuration of the network layers
    var layerConfiguration: [MKLayerConfiguration]
    /// Activation function that gets applied to every layer but the output layer
    //var hiddenActivation: MKActivationFunction
    /// Activation function that gets applied to the output of the last layer
    //var outputActivation: MKActivationFunction
    /// The value of the bias unit, if used
    var biasValue: Float = 1.0
    /// Number of bias units per activation layer
    var biasUnits = 1
    
    var maxNumberOfHiddenFeatures: Int {
        let max = layerConfiguration.maxElement { x, y in return x.size < y.size }
        return max!.size + biasUnits
    }
}

public enum MKForwardPropagatorError : ErrorType {
    case InvalidWeightsForLayerConfiguration
    case InvalidFeatureMatrixSize
}

public class MKForwardPropagator {
    public typealias Element = Float
    /// The number of elements in the feature vector
    private let featureVectorSize: Int
    /// The number of elements in the feature vector
    private let predictionVectorSize: Int
    /// Maximal number of hidden activation units in a layer
    private let maxNumberOfHiddenFeatures: Int
    /// Layers and their weights
    private let layers: [MKForwardPropagatorLayer]
    /// Configuration values of the propagator
    private let conf: MKForwardPropagatorConfiguration
    
    private init(configuration: MKForwardPropagatorConfiguration, weights: [Element]) {
        self.featureVectorSize = configuration.layerConfiguration.first!.size
        self.predictionVectorSize = configuration.layerConfiguration.last!.size
        self.conf = configuration
        self.maxNumberOfHiddenFeatures = configuration.maxNumberOfHiddenFeatures
        self.layers = MKForwardPropagator.buildLayers(configuration, weights: weights)
    }
    
    ///
    /// Given the propagators configuration and the layer weights, construct the layers to be used during forward
    /// propagation.
    ///
    private static func buildLayers(configuration: MKForwardPropagatorConfiguration,
        weights: [Element]) -> [MKForwardPropagatorLayer] {
        var layers = [MKForwardPropagatorLayer]()
            
        let numLayers = configuration.layerConfiguration.count - 1
        
        // An offset between the weight matrices of different layers
        var crossLayerOffset = 0
        for j in 0..<numLayers { // Recall we don't need a matrix for the input layer
            
            // If network has X units in layer j, and Y units in layer j+1, then weight matrix for layer j
            // will be of demension: [ Y x (X+1) ]
            let rowCount = configuration.layerConfiguration[j + 1].size
            let columnCount = configuration.layerConfiguration[j].size + configuration.biasUnits
            var layerWeights = [Element](count: rowCount * columnCount, repeatedValue: 0.0)
            
            var totalOffset = 0
            for row in 0..<rowCount {
                for col in 0..<columnCount {
                    // Simulate the matrix using row-major ordering
                    let crossRowOffset = col + row * columnCount
                    // Now matrix[offset] corresponds to M[row, col]
                    totalOffset = crossRowOffset + crossLayerOffset
                    layerWeights[crossRowOffset] = weights[totalOffset]
                }
            }
            
            layers.append(MKForwardPropagatorLayer(
                rowCount: rowCount,
                columnCount: columnCount,
                weights: layerWeights,
                activationFunction: configuration.layerConfiguration[j].activationFunction))
            
            crossLayerOffset = totalOffset + 1; // Adjust offset to the next layer
        }
        return layers
    }
    
    
    public static func configured(configuration: MKForwardPropagatorConfiguration, weights: [Element]) throws -> MKForwardPropagator {
        if MKForwardPropagator.getWeightsCount(configuration.layerConfiguration) != weights.count || configuration.layerConfiguration.isEmpty {
            throw MKForwardPropagatorError.InvalidWeightsForLayerConfiguration
        }
        
        return MKForwardPropagator(configuration: configuration, weights: weights)
    }
    
    ///
    /// Number of weights needed for a given layer configuration
    ///
    private static func getWeightsCount(layerConfiguration: [MKLayerConfiguration]) -> Int {
        var result = 0
        for var i = 0; i < layerConfiguration.count - 1; ++i {
            result += (layerConfiguration[i].size + 1) * layerConfiguration[i + 1].size
        }
        return result
    }
    
    ///
    /// Calculate the number of layers in this network
    ///
    private func numberOfLayers() -> Int {
        return layers.count
    }
    
    ///
    /// Helper to swap two array references
    ///
    private func swap(inout a: [Element], inout _ b: [Element]) {
        let temporaryA = a
        a = b
        b = temporaryA
    }
    
    ///
    /// Feed the input data through the neural network using forward propagation. The passed
    /// matrix should contain the feature values for one or multiple examples.
    ///
    public func predictFeatureMatrix(matrix: UnsafePointer<Float>, length: Int) throws -> [Element] {
        let numExamples = length / self.featureVectorSize;
        var biasValue = conf.biasValue
        let numberOfBiasUnits = conf.biasUnits * numExamples
        
        try checkInputSanity(matrix, length: length)
        
        var currentInputs = [Element](count: self.maxNumberOfHiddenFeatures * numExamples, repeatedValue: 0)
        var buffer = [Element](count: self.maxNumberOfHiddenFeatures * numExamples, repeatedValue: 0)
        
        // Copy feature-matrix into the buffer. We will transpose the feature matrix to get the
        // bias units in a row instead of a column for easier updates.
        vDSP_mtrans(
            matrix, vDSP_Stride(1),
            &currentInputs[numberOfBiasUnits], vDSP_Stride(1),
            vDSP_Length(self.featureVectorSize),
            vDSP_Length(numExamples));
        
        // Forward propagation algorithm
        for j in 0..<self.numberOfLayers() {
            // 1. Add the bias unit in row 0 and propagate features to the next level
            if conf.biasUnits > 0 {
                vDSP_vfill(
                    &biasValue,
                    &currentInputs, vDSP_Stride(1),
                    vDSP_Length(numberOfBiasUnits))
            }
            
            // 2. Calculate hidden features for current layer j
            vDSP_mmul(
                layers[j].weights, vDSP_Stride(1),
                currentInputs, vDSP_Stride(1),
                &buffer[numberOfBiasUnits], vDSP_Stride(1),
                vDSP_Length(layers[j].rowCount),
                vDSP_Length(numberOfBiasUnits),
                vDSP_Length(layers[j].columnCount));
            
            swap(&buffer, &currentInputs)
            
            // 3. Apply activation function, e.g. logistic func
            //let activationFunction = layers[j].isOutputLayer ? conf.outputActivation : conf.hiddenActivation
            let feature_length = layers[j].rowCount * numExamples
            layers[j].activationFunction.applyOn(&currentInputs, offset: numberOfBiasUnits, length: feature_length)
            // activationFunction.applyOn(&currentInputs, offset: numberOfBiasUnits, length: feature_length)
        }
        
        return Array(currentInputs[numberOfBiasUnits..<numberOfBiasUnits+(self.predictionVectorSize * numExamples)])
    }
    
    ///
    /// Make sure the input we received to do the forward propagation with is correctly formated, e.g.
    /// contains the expected number of features.
    ///
    private func checkInputSanity(matrix: UnsafePointer<Float>, length: Int) throws {
        let numExamples = length / self.featureVectorSize;
        
        if (length != self.featureVectorSize * numExamples || length == 0) {
            throw MKForwardPropagatorError.InvalidFeatureMatrixSize
        }
    }
    
    
}
