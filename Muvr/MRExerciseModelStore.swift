import MuvrKit

public struct MRExerciseModel {
    let id: String
    let version: String
    var labels: NSURL? = nil
    var layers: NSURL? = nil
    var weights: NSURL? = nil
    
    init(id: String, version: String) {
        self.id = id
        self.version = version
    }
    
    func isComplete() -> Bool {
        return labels != nil && layers != nil && weights != nil
    }
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
    
    enum Filetype: String {
        case layers
        case labels
        case weights
    }

    let models: [String:MRExerciseModel]
    
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
    private static func bundledModels() -> [String:MRExerciseModel] {
        let bundlePath = NSBundle.mainBundle().pathForResource("Models", ofType: "bundle")!
        let bundle = NSBundle(path: bundlePath)!
        
        func bundledModel(id: String) -> MRExerciseModel? {
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
                  let (modelKey, filetype) = MRExerciseModelStore.parseFilename(filename) else { return models }
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

    /// expected file format is ``modelId_version_model.type.ext``
    private static func parseFilename(filename: String) -> (ModelKey, Filetype)? {
        do {
            let pattern = try NSRegularExpression(pattern: "(.+)_(.+)_model\\.(weights|labels|layers)\\.(.{3})", options: [])
            let matches = filename.matchingGroups(pattern, groups: 3)
            guard matches.count >= 3,
              let filetype = Filetype(rawValue: matches[2]) else { return nil }
            let id = matches[0]
            let version = matches[1]
            return (ModelKey(id: id, version: version), filetype)
        } catch {
            return nil
        }
    }
    
}

///
/// Implementation of Equatable for ModelKey
///
func ==(model1: MRExerciseModelStore.ModelKey, model2: MRExerciseModelStore.ModelKey) -> Bool {
    return model1.id == model2.id && model1.version == model2.version
}