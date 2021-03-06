import Foundation

///
/// Adds mechanism to load the model from storage
///
extension MKExerciseModel {
    
    /// The load errors
    enum LoadError : ErrorType {
        /// Missing component like labels or layers
        case MissingModelComponent(name: String)
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
    public init(fromBundle bundle: NSBundle, id: MKExerciseModel.Id, labelExtractor: String -> Label) throws {
        guard let layersConfigurationPath = bundle.pathForResource("\(id)_model.layers", ofType: "txt") else {
            throw LoadError.MissingModelComponent(name: "\(id)_model.layers")
        }
        guard let labelsPath = bundle.pathForResource("\(id)_model.labels", ofType: "txt") else {
            throw LoadError.MissingModelComponent(name: "\(id)_model.labels")
        }
        guard let weightsPath = bundle.pathForResource("\(id)_model.weights", ofType: "raw") else {
            throw LoadError.MissingModelComponent(name: "\(id)_model.weights")
        }
        try self.init(layersPath: layersConfigurationPath, labelsPath: labelsPath, weightsPath: weightsPath, labelExtractor: labelExtractor)
    }
    
    public init(layersPath: String, labelsPath: String, weightsPath: String, labelExtractor: String -> Label) throws {
        // load the layer configuration
        let layerConfiguration = try MKLayerConfiguration.parse(text: try! String(contentsOfFile: layersPath, encoding: NSUTF8StringEncoding))
        
        // load the labels
        let labelNames = try String(contentsOfFile: labelsPath, encoding: NSUTF8StringEncoding)
            .stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
            .componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        let labels = labelNames.map(labelExtractor)
        
        // load the weights
        let weightsData = NSData(contentsOfFile: weightsPath)!
        let weightsCount = weightsData.length / sizeof(Float)
        var weights = [Float](count: weightsCount, repeatedValue: 0)
        weightsData.getBytes(&weights, length: weightsData.length)
        
        // TODO: load the sensorDataTypes
        let sensorDataTypes: [MKSensorDataType] = [.Accelerometer(location: .LeftWrist)]
        
        // TODO: load minimum duration
        let minimumDuration = 8.0
        
        self.init(layerConfiguration: layerConfiguration, weights: weights,
            sensorDataTypes: sensorDataTypes,
            labels: labels,
            minimumDuration: minimumDuration)
    }
    
    internal static func loadWeightsFromFile(path: String) -> [Float] {
        let data = NSData(contentsOfFile: path)!
        let count = data.length / sizeof(Float)
        // create array of appropriate length:
        var weights = [Float](count: count, repeatedValue: 0)
        // copy bytes into array
        data.getBytes(&weights, length: data.length)
        return weights
    }
    
}