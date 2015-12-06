import MuvrKit

public typealias MRExerciseModelVersion = String

public struct MRExerciseModel {
    let id: MKExerciseModelId
    let version: MRExerciseModelVersion
    var labels: NSURL? = nil
    var layers: NSURL? = nil
    var weights: NSURL? = nil
    
    init(id: MKExerciseModelId, version: MRExerciseModelVersion) {
        self.id = id
        self.version = version
    }
    
    func isComplete() -> Bool {
        return labels != nil && layers != nil && weights != nil
    }
    
    /// expected file format is ``modelId_version_model.type.ext``
    static func parseFilename(filename: String) -> (MKExerciseModelId, MRExerciseModelVersion, MRExerciseModelFileType)? {
        do {
            let pattern = try NSRegularExpression(pattern: "(.+)_(.+)_model\\.(weights|labels|layers)\\.(.{3})", options: [])
            let matches = filename.matchingGroups(pattern, groups: 3)
            guard matches.count >= 3,
                let filetype = MRExerciseModelFileType(rawValue: matches[2]) else { return nil }
            let id = matches[0]
            let version = matches[1]
            return (id, version, filetype)
        } catch {
            return nil
        }
    }
}

public enum MRExerciseModelFileType: String {
    case layers
    case labels
    case weights
}
///
/// Takes care of loading models from files by looking into the ``Application Support`` folder
///
public class MRExerciseModelStore {
    
    /// Models are identified by ``id`` and ``version``
    struct ModelKey: Equatable, Hashable {
        let id: String
        let version: String
        var hashValue: Int {
            return "\(id),\(version)".hashValue
        }
    }

    private(set) var models: [MKExerciseModelId:MRExerciseModel]
    
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
            let key = ModelKey(id: id, version: "0")
            var model = MRExerciseModel(id: key.id, version: key.version)
            model.layers = layersUrl
            model.labels = labelsUrl
            model.weights = weightsUrl
            return model
        }
        
        return ["slacking":bundledModel("slacking")!, "arms":bundledModel("arms")!]
    }

    /// load any model located in ``Application Support`` folder
    private static func downloadedModels() -> [ModelKey: MRExerciseModel] {
        let fileManager = NSFileManager.defaultManager()
        guard let supportDir = fileManager.URLsForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomains: .UserDomainMask).first,
            let modelsUrl = try? fileManager.contentsOfDirectoryAtURL(supportDir, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
        else { return [:] }
        let models = modelsUrl.reduce([:]) { (var models: [ModelKey:MRExerciseModel], modelUrl: NSURL) in
            guard let filename = modelUrl.lastPathComponent,
                  let (modelId, version, filetype) = MRExerciseModel.parseFilename(filename) else { return models }
            let modelKey = ModelKey(id: modelId, version: version)
            var model = models[modelKey] ?? MRExerciseModel(id: modelKey.id, version: modelKey.version)
            switch (filetype) {
                case .layers:  model.layers = modelUrl
                case .labels:  model.labels = modelUrl
                case .weights: model.weights = modelUrl
            }
            models[modelKey] = model
            return models
        }
        return models
    }
    
    /// Store a new model by moving its files into the ``Application Support`` folder
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

        var newModel = MRExerciseModel(id: model.id, version: model.version)
        newModel.labels = moveFile(model.labels)
        newModel.layers = moveFile(model.layers)
        newModel.weights = moveFile(model.weights)
        guard newModel.isComplete() else { return nil }
        if let existingModel = models[newModel.id] where existingModel.version < newModel.version {
            models[newModel.id] = newModel
        }
        return newModel
    }
    
}

///
/// Implementation of Equatable for ModelKey
///
func ==(model1: MRExerciseModelStore.ModelKey, model2: MRExerciseModelStore.ModelKey) -> Bool {
    return model1.id == model2.id && model1.version == model2.version
}