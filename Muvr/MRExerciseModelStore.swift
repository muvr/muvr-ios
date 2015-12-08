import MuvrKit

///
/// Takes care of loading models from files by looking into the ``Application Support`` folder
///
class MRExerciseModelStore: MKExerciseModelSource {
    
    enum ExerciseModelStoreError: ErrorType {
        case MissingClassificationModel(model: String)
    }

    private let storage: MRCloudStorage
    private(set) var models: [MKExerciseModelId:MRExerciseModel]
    
    var modelsMetadata: [MKExerciseModelMetadata] {
        return models.keys.flatMap { id in
            guard id != "slacking" else { return nil }
            return (id, id.capitalizedString)
        }
    }
    
    private static var supportDir: NSURL? {
        return NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomains: .UserDomainMask).first
    }
    
    init(cloudStorage: MRCloudStorage) {
        self.storage = cloudStorage
        let bundledModels = MRExerciseModelStore.bundledModels()
        let downloadedModels = MRExerciseModelStore.downloadedModels()
        // keep only models with latest version
        self.models = downloadedModels.values
            .filter { return $0.isComplete }
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
            return MRExerciseModel(id: id, version: 0, labels: labelsUrl, layers: layersUrl, weights: weightsUrl)
        }
        
        return ["slacking":bundledModel("slacking")!, "arms":bundledModel("arms")!]
    }

    /// load any model located in ``Application Support`` folder
    private static func downloadedModels() -> [MKExerciseModelId: MRExerciseModel] {
        let fileManager = NSFileManager.defaultManager()
        guard let dir = supportDir else { return [:]}
        
        guard let modelUrls = try? fileManager.contentsOfDirectoryAtURL(dir, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
        else { return [:] }
        
        return MRExerciseModel.latestModels(modelUrls)
    }
    
    ///
    /// Download any new classification model from the remote storage
    ///
    func downloadModels(continuation: () -> Void) {
        guard let supportDir = MRExerciseModelStore.supportDir else { return }

        storage.listModels { models in
            // keep only newer or unknown models
            let modelsToDownload = (models ?? []).filter { m in
                guard let existingModel = self.models[m.id] else { return true }
                return m.version > existingModel.version
            }
            if modelsToDownload.isEmpty {
                continuation()
                return
            }
            // and download each one of them
            var downloaded = 0
            modelsToDownload.forEach { model in
                self.storage.downloadModel(model, dest: supportDir) { m in
                    if let m = m where m.isComplete {
                        self.models[m.id] = m
                    }
                    downloaded += 1
                    if (downloaded == modelsToDownload.count) {
                        continuation()
                    }
                }
            }
        }
    }
    
    ///
    /// Returns the ``MKExerciseModel`` for the requested id
    /// throws ``MissingClassificationModel`` error when the requested model is not found
    ///
    func getExerciseModel(id id: MKExerciseModelId) throws -> MKExerciseModel {
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