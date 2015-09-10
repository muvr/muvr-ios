import Foundation

/// TODO: consider moving to MRMuscleGroupModel, which lives in its own table
extension MRExerciseModel {
    private static let bundlePath = NSBundle.mainBundle().pathForResource("Models", ofType: "bundle")!
 
    ///
    /// Loads and constructs MRModelParameters for the given model
    ///
    var modelParameters: MRModelParameters? {
        get {
            if let weightsPath = NSBundle(path: MRExerciseModel.bundlePath)?.pathForResource(id, ofType: "raw") {
                if let weights = NSData(contentsOfFile: weightsPath) {
                    return MRModelParameters(weights: weights, andLabels: exercises)
                }
            }
            
            return nil
        }
    }
    
}