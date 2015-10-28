import Foundation

struct MKForwardPropagatorLayer<A> {
    let rowCount: Int
    let columnCount: Int
    let weights: [A]
}

public enum MKForwardPropagatorError : ErrorType {
    case InvalidWeightsForLayerConfiguration
}

public class MKForwardPropagator {
    public typealias Element = Float
    /// The layer configuration is simply the number of perceptrons in each layer
    public typealias LayerConfiguration = [Int]
    /// The number of elements in the feature vector
    private let featureVectorSize: Int
    
    private init(layerConfiguration: LayerConfiguration, weights: [Element]) {
        self.featureVectorSize = layerConfiguration.first!
        
    }
    
    public static func configured(layerConfiguration: LayerConfiguration, weights: [Element]) throws -> MKForwardPropagator {
        if MKForwardPropagator.getWeightsCount(layerConfiguration) != weights.count {
            throw MKForwardPropagatorError.InvalidWeightsForLayerConfiguration
        }

        return MKForwardPropagator(layerConfiguration: layerConfiguration, weights: weights)
    }
    
    private static func getWeightsCount(layerConfiguration: LayerConfiguration) -> Int {
        var result: Int = 0
        for var i = 0; i < layerConfiguration.count - 1; ++i {
            result += (layerConfiguration[i] + 1) * layerConfiguration[i + 1]
        }
        return result
    }
    
    func predictFeatureMatrix(matrix: [Element]) -> [Element] {
        return []
    }
    
}
