import MuvrKit

///
/// Takes care of loading models from files by looking into the ``Application Support`` folder
///
public class MRExerciseModelStore: MKExerciseModelSource {
    
    enum ExerciseModelStoreError: ErrorType {
        case MissingClassificationModel(model: String)
    }

    private(set) var models: [MKExerciseModelId:MRExerciseModel]
    
    var modelIds: [MKExerciseModelId] {
        return Array(models.keys)
    }
    
    public init() {
        let bundledModels = MRExerciseModelStore.bundledModels()
        let downloadedModels = MRExerciseModelStore.downloadedModels()
        // keep only models with latest version
        self.models = downloadedModels.values
            .filter { return $0.isComplete() }
            .reduce(bundledModels) { (var models, model) in
                let id = model.id
                let m = models[id]
                if m == nil ||  m!.version < model.version {
                    models[id] = model
                }
                return models
            }
    }
    
    /// load arms and slacking models from bundle
    private static func bundledModels() -> [MKExerciseModelId:MRExerciseModel] {
        let bundlePath = NSBundle.mainBundle().pathForResource("Models", ofType: "bundle")!
        let bundle = NSBundle(path: bundlePath)!
        
        func bundledModel(id: MKExerciseModelId) -> MRExerciseModel? {
            guard let layersUrl = bundle.URLForResource("\(id)_model.layers", withExtension: "txt"),
                  let labelsUrl = bundle.URLForResource("\(id)_model.labels", withExtension: "txt"),
                  let weightsUrl = bundle.URLForResource("\(id)_model.weights", withExtension: "raw") else { return nil }
            return MRExerciseModel(id: id, version: "0", labels: labelsUrl, layers: layersUrl, weights: weightsUrl)
        }
        
        return ["slacking":bundledModel("slacking")!, "arms":bundledModel("arms")!]
    }

    /// load any model located in ``Application Support`` folder
    private static func downloadedModels() -> [MKExerciseModelId: MRExerciseModel] {
        let fileManager = NSFileManager.defaultManager()
        guard let supportDir = fileManager.URLsForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomains: .UserDomainMask).first,
            let modelUrls = try? fileManager.contentsOfDirectoryAtURL(supportDir, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
        else { return [:] }
        return MRExerciseModel.latestModels(modelUrls)
    }
    
    ///
    /// Store a new model by moving its files into the ``Application Support`` folder
    ///
    func store(model model: MRExerciseModel) -> MRExerciseModel? {
        let fileManager = NSFileManager.defaultManager()
        guard let supportDir = fileManager.URLsForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomains: .UserDomainMask).first
            else { return nil }
        
        func moveFile(source: NSURL?) -> NSURL? {
            guard let source = source,
                  let filename = source.lastPathComponent else { return nil }
            let dest = NSURL(fileURLWithPath: filename, isDirectory: false, relativeToURL: supportDir)
            do {
                try fileManager.moveItemAtURL(source, toURL: dest)
            } catch {
                return nil
            }
            return dest
        }

        let newModel = MRExerciseModel(id: model.id, version: model.version, labels: moveFile(model.labels), layers: moveFile(model.layers), weights: moveFile(model.weights))
        
        guard newModel.isComplete() else { return nil }
        
        if let existingModel = models[newModel.id] where existingModel.version < newModel.version {
            models[newModel.id] = newModel
        }
        
        return newModel
    }
    
    ///
    /// Returns the ``MKExerciseModel`` for the requested id
    /// throws ``MissingClassificationModel`` error when the requested model is not found
    ///
    public func getExerciseModel(id id: MKExerciseModelId) throws -> MKExerciseModel {
        // setup the classifier
        guard let model = models[id],
            let layersPath = model.layers?.path,
            let labelsPath = model.labels?.path,
            let weightsPath = model.weights?.path
            else { throw ExerciseModelStoreError.MissingClassificationModel(model: id)
        }
        return try MKExerciseModel(layersPath: layersPath, labelsPath: labelsPath, weightsPath: weightsPath)
    }
    
    /// 
    /// Returns the list of exercises available in a given model
    ///
    func exerciseIds(model id: MKExerciseModelId) -> [MKExerciseId] {
        let model = try? getExerciseModel(id: id)
        return model?.exerciseIds ?? []
    }
    
    
}