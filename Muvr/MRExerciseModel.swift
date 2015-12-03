import MuvrKit

public typealias MRExerciseModelVersion = String

public struct MRExerciseModel {
    let id: MKExerciseModelId
    let version: MRExerciseModelVersion
    let labels: NSURL?
    let layers: NSURL?
    let weights: NSURL?
    
    init(id: MKExerciseModelId, version: MRExerciseModelVersion, labels: NSURL?, layers: NSURL?, weights: NSURL?) {
        self.id = id
        self.version = version
        self.labels = labels
        self.layers = layers
        self.weights = weights
    }
    
    init(id: MKExerciseModelId, version: MRExerciseModelVersion) {
        self.init(id: id, version: version, labels: nil, layers: nil, weights: nil)
    }
    
    func isComplete() -> Bool {
        return labels != nil && layers != nil && weights != nil
    }
    
    internal func with(labels newLabels: NSURL) -> MRExerciseModel {
        return MRExerciseModel(id: id, version: version, labels: newLabels, layers: layers, weights: weights)
    }
    
    internal func with(layers newLayers: NSURL) -> MRExerciseModel {
        return MRExerciseModel(id: id, version: version, labels: labels, layers: newLayers, weights: weights)
    }
    
    internal func with(weights newWeights: NSURL) -> MRExerciseModel {
        return MRExerciseModel(id: id, version: version, labels: labels, layers: layers, weights: newWeights)
    }
    
    ///
    /// Extract the most recent models from a list of files (urls)
    ///
    static func latestModels(urls: [NSURL]) -> [MKExerciseModelId:MRExerciseModel] {
        
        enum MRExerciseModelFileType: String {
            case layers
            case labels
            case weights
        }
        
        /// expected file format is ``modelId_version_model.type.ext``
        func parseFilename(filename: String) -> (MKExerciseModelId, MRExerciseModelVersion, MRExerciseModelFileType)? {
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
        
        /// transforms a list of models into a dict containing only latest models
        func latest(models: [MRExerciseModel]) -> [MKExerciseModelId:MRExerciseModel] {
            var latestModels: [MKExerciseModelId:MRExerciseModel] = [:]
            for model in models {
                if let latestModel = latestModels[model.id] where latestModel.version > model.version {
                    continue
                }
                latestModels[model.id] = model
            }
            return latestModels
        }
        
        /// transforms a list of model files (urls) into a list of models
        func models(urls: [NSURL]) -> [MRExerciseModel] {
            var models: [MRExerciseModel] = []
            for url in urls {
                guard let filename = url.lastPathComponent,
                    let (modelId, version, filetype) = parseFilename(filename)
                    else { continue }
                
                let index = models.indexOf { $0.id == modelId && $0.version == version } ?? models.count
                var model = index < models.count ? models[index] : MRExerciseModel(id: modelId, version: version)
                
                switch (filetype) {
                case .layers:  model = model.with(layers: url)
                case .labels:  model = model.with(labels: url)
                case .weights: model = model.with(weights: url)
                }
                
                models[index] = model
            }
            return models.filter { return $0.isComplete() }
        }
        
        return latest(models(urls))
    }
}