import Foundation

///
/// Adds mechanism to load the model from storage
///
extension MKExerciseModel {
    
    /// The load errors
    enum LoadError : ErrorProtocol {
        /// Missing component like labels or layers
        case missingModelComponent(name: String)
    }
    
    ///
    /// Loads the ``MKExerciseModel`` from a collection of files in the given ``bundle``. The files must
    /// have the following naming convention:
    ///
    /// - layer configuration: ``id``_layers.txt,
    /// - labels: ``id``_labels.txt,
    /// - weights: ``id``_weights.raw
    ///
    /// Moreover, the contents of the files must be parseable using the basic text parsing mechanism
    /// in ``MKActivationFunction`` and ``MKLayerConfiguration``.
    ///
    public init(fromBundle bundle: Bundle, id: MKExerciseModel.Id, labelExtractor: (String) -> Label) throws {
        guard let layersConfigurationPath = bundle.pathForResource("\(id)_model.layers", ofType: "txt") else {
            throw LoadError.missingModelComponent(name: "\(id)_model.layers")
        }
        guard let labelsPath = bundle.pathForResource("\(id)_model.labels", ofType: "txt") else {
            throw LoadError.missingModelComponent(name: "\(id)_model.labels")
        }
        guard let weightsPath = bundle.pathForResource("\(id)_model.weights", ofType: "raw") else {
            throw LoadError.missingModelComponent(name: "\(id)_model.weights")
        }
        try self.init(layersPath: layersConfigurationPath, labelsPath: labelsPath, weightsPath: weightsPath, labelExtractor: labelExtractor)
    }
    
    public init(layersPath: String, labelsPath: String, weightsPath: String, labelExtractor: (String) -> Label) throws {
        // load the layer configuration
        let layerConfiguration = try MKLayerConfiguration.parse(text: try! String(contentsOfFile: layersPath, encoding: String.Encoding.utf8))
        
        // load the labels
        let labelNames = try String(contentsOfFile: labelsPath, encoding: String.Encoding.utf8)
            .trimmingCharacters(in: CharacterSet.newlines)
            .components(separatedBy: CharacterSet.newlines)
        let labels = labelNames.map(labelExtractor)
        
        // load the weights
        let weightsData = try! Data(contentsOf: URL(fileURLWithPath: weightsPath))
        let weightsCount = weightsData.count / sizeof(Float.self)
        var weights = [Float](repeating: 0, count: weightsCount)
        (weightsData as NSData).getBytes(&weights, length: weightsData.count)
        
        // TODO: load the sensorDataTypes
        let sensorDataTypes: [MKSensorDataType] = [.accelerometer(location: .leftWrist)]
        
        // TODO: load minimum duration
        let minimumDuration = 8.0
        
        self.init(layerConfiguration: layerConfiguration, weights: weights,
            sensorDataTypes: sensorDataTypes,
            labels: labels,
            minimumDuration: minimumDuration)
    }
    
    internal static func loadWeightsFromFile(_ path: String) -> [Float] {
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let count = data.count / sizeof(Float.self)
        // create array of appropriate length:
        var weights = [Float](repeating: 0, count: count)
        // copy bytes into array
        (data as NSData).getBytes(&weights, length: data.count)
        return weights
    }
    
}
