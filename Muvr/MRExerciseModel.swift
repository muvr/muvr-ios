import MuvrKit

typealias MRExerciseModelVersion = Int

enum MRExerciseModelFileType: String {
    case labels
    case layers
    case weights
}

struct MRExerciseModel {
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
    
    var isComplete: Bool {
        return labels != nil && layers != nil && weights != nil
    }
    
    internal func with(labels newLabels: NSURL?) -> MRExerciseModel {
        return MRExerciseModel(id: id, version: version, labels: newLabels, layers: layers, weights: weights)
    }
    
    internal func with(layers newLayers: NSURL?) -> MRExerciseModel {
        return MRExerciseModel(id: id, version: version, labels: labels, layers: newLayers, weights: weights)
    }
    
    internal func with(weights newWeights: NSURL?) -> MRExerciseModel {
        return MRExerciseModel(id: id, version: version, labels: labels, layers: layers, weights: newWeights)
    }
}