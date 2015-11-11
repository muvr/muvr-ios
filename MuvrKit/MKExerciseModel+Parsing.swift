import Foundation

///
/// Adds mechanism to load the model from storage
///
extension MKExerciseModel {
    
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
    public static func loadFromBundle(bundle: NSBundle, id: MKExerciseModelId) throws -> MKExerciseModel {
        
        func loadWeightsFromFile(path: String) -> [Float] {
            let data = NSData(contentsOfFile: path)!
            let count = data.length / sizeof(Float)
            // create array of appropriate length:
            var weights = [Float](count: count, repeatedValue: 0)
            // copy bytes into array
            data.getBytes(&weights, length: data.length)
            return weights
        }
        
        // load the layer configuration
        let layersConfigurationPath = bundle.pathForResource("\(id)_model.layers", ofType: "txt")!
        let layerConfiguration = try MKLayerConfiguration.parse(text: try! String(contentsOfFile: layersConfigurationPath, encoding: NSUTF8StringEncoding))
        
        // load the labels
        let labelsPath = bundle.pathForResource("\(id)_model.labels", ofType: "txt")!
        let labels = try String(contentsOfFile: labelsPath, encoding: NSUTF8StringEncoding).componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())

        // load the weights
        let weightsPath = bundle.pathForResource("\(id)_model.weights", ofType: "raw")!
        let weightsData = NSData(contentsOfFile: weightsPath)!
        let weightsCount = weightsData.length / sizeof(Float)
        var weights = [Float](count: weightsCount, repeatedValue: 0)
        weightsData.getBytes(&weights, length: weightsData.length)
        
        // TODO: load the sensorDataTypes
        let sensorDataTypes: [MKSensorDataType] = [.Accelerometer(location: .LeftWrist)]
        
        // TODO: load minimum duration
        let minimumDuration = 8.0
        
        return MKExerciseModel(layerConfiguration: layerConfiguration, weights: weights,
            sensorDataTypes: sensorDataTypes,
            exerciseIds: labels,
            minimumDuration: minimumDuration)
    }
    
    

}