import MuvrKit

///
/// Takes care of loading models from files by looking into the ``Application Support`` folder
///
class MRExerciseModelStore: MKExerciseModelSource {
    
    enum ExerciseModelStoreError: ErrorType {
        case MissingClassificationModel(model: String)
    }
    
    private let storageAccess: MRStorageAccessProtocol
    private(set) var models: [MKExerciseModel.Id:MRExerciseModel]
    
    private static var supportDir: NSURL? {
        return NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomains: .UserDomainMask).first
    }
    
    init(storageAccess: MRStorageAccessProtocol) {
        self.storageAccess = storageAccess
        let bundledModels = MRExerciseModelStore.bundledModels
        let downloadedModels = MRExerciseModelStore.downloadedModels
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
    private static var bundledModels: [MKExerciseModel.Id:MRExerciseModel] {
        let bundlePath = NSBundle.mainBundle().pathForResource("Models", ofType: "bundle")!
        let bundle = NSBundle(path: bundlePath)!
        
        func bundledModel(id: MKExerciseModel.Id) -> MRExerciseModel? {
            guard let layersUrl = bundle.URLForResource("\(id)_model.layers", withExtension: "txt"),
                  let labelsUrl = bundle.URLForResource("\(id)_model.labels", withExtension: "txt"),
                  let weightsUrl = bundle.URLForResource("\(id)_model.weights", withExtension: "raw") else { return nil }
            return MRExerciseModel(id: id, version: 0, labels: labelsUrl, layers: layersUrl, weights: weightsUrl)
        }
        
        return ["slacking":bundledModel("slacking")!, "arms":bundledModel("arms")!]
    }
    
    /// load any model located in ``Application Support`` folder
    private static var downloadedModels: [MKExerciseModel.Id: MRExerciseModel] {
        let fileManager = NSFileManager.defaultManager()
        guard let dir = supportDir else { return [:]}
        if let path = dir.path where !fileManager.fileExistsAtPath(path) {
            // directory doesn't exists, create it
            do { try fileManager.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil) }
            catch let e { NSLog("Failed to create support dir - won't be able to download new models: \(e)") }
        }
        guard let modelUrls = try? fileManager.contentsOfDirectoryAtURL(dir, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
        else { return [:] }
        
        return MRExerciseModel.latestModels(modelUrls)
    }
    
    ///
    /// list models remotely available
    ///
    private func listRemoteModels(continuation: [MRExerciseModel]? -> Void) {
        storageAccess.listFiles("/models") { urls in
            guard let urls = urls else {
                continuation(nil)
                return
            }
            let models = MRExerciseModel.latestModels(urls).values.filter { m in
                guard let existingModel = self.models[m.id] else { return true }
                return m.version > existingModel.version
            }
            continuation(Array(models))
        }
    }
    
    ///
    /// download a given model from remote storage
    ///
    private func downloadModel(model: MRExerciseModel, continuation: MRExerciseModel? -> Void) {
        guard model.isComplete else { return }
        
        let fileManager = NSFileManager.defaultManager()
        var downloaded = 0
        var newModel = MRExerciseModel(id: model.id, version: model.version)
        
        func checkCompletion() {
            if ++downloaded == 3 { continuation(newModel) }
        }
        
        func processFile(src: NSURL?, filename: String?) -> NSURL? {
            guard let filename = filename,
                  let src = src,
                  let dest = MRExerciseModelStore.supportDir?.URLByAppendingPathComponent(filename) else { return nil }
            do {
                try fileManager.moveItemAtURL(src, toURL: dest)
                return dest
            } catch { return nil }
        }
        
        storageAccess.downloadFile(model.weights!) { url in
            newModel = newModel.with(weights: processFile(url, filename: model.weights?.lastPathComponent))
            checkCompletion()
        }
        
        storageAccess.downloadFile(model.layers!) { url in
            newModel = newModel.with(layers: processFile(url, filename: model.layers?.lastPathComponent))
            checkCompletion()
        }
        
        storageAccess.downloadFile(model.labels!) { url in
            newModel = newModel.with(labels: processFile(url, filename: model.labels?.lastPathComponent))
            checkCompletion()
        }
    }
    
    ///
    /// Download any new classification model from the remote storage
    ///
    func downloadModels(continuation: () -> Void) {
        listRemoteModels { models in
            guard let models = models where !models.isEmpty else {
                    continuation()
                    return
            }
            // and download each one of them
            var downloaded = models.count
            models.forEach { model in
                self.downloadModel(model) { m in
                    if let m = m where m.isComplete { self.models[m.id] = m }
                    if (--downloaded == 0) { continuation() }
                }
            }
        }
    }
    
    ///
    /// Returns the ``MKExerciseModel`` for the requested id
    /// throws ``MissingClassificationModel`` error when the requested model is not found
    ///
    func getExerciseModel(id id: MKExerciseModel.Id) throws -> MKExerciseModel {
        // setup the classifier
        guard let model = models[id],
              let layersPath = model.layers?.path,
              let labelsPath = model.labels?.path,
              let weightsPath = model.weights?.path
        else { throw ExerciseModelStoreError.MissingClassificationModel(model: id) }
        return try MKExerciseModel(layersPath: layersPath, labelsPath: labelsPath, weightsPath: weightsPath) { x in
            return (x, MKExerciseTypeDescriptor(exerciseId: x)!)
        }
    }
    
    ///
    /// Returns the list of exercises available in a given model
    ///
    func exerciseIds(model id: MKExerciseModel.Id) -> [MKExerciseModel.Label] {
        let model = try? getExerciseModel(id: id)
        return model?.labels ?? []
    }
    
    ///
    /// Delete the downloaded models
    ///
    func reset() {
        let fileManager = NSFileManager.defaultManager()
        guard let dir = MRExerciseModelStore.supportDir,
              let modelUrls = try? fileManager.contentsOfDirectoryAtURL(dir, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
        else { return }
        modelUrls.forEach { url in
            do {
                try fileManager.removeItemAtURL(url)
            } catch let error {
                NSLog("Failed to remove \(url): \(error)")
            }
        }
        models = MRExerciseModelStore.bundledModels
    }
    
}
