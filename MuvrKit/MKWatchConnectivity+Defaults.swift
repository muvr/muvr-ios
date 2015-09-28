import Foundation

///
/// Extension containing defaul values
///
extension MKConnectivity {
    
    ///
    /// Default exercise models that will be reported in case no models are found from the app
    ///
    internal var defaultExerciseModels: [MKExerciseModel] {
        return [
            MKExerciseModel(id: "arms",      title: "Arms",      exerciseIds: ["arms/biceps-curl", "arms/triceps-extension"]),
            MKExerciseModel(id: "shoulders", title: "Shoulders", exerciseIds: ["shoulders/lateral-raise", "shoulders/press", "shoulders/pull-up"]),
            MKExerciseModel(id: "chest",     title: "Chest",     exerciseIds: ["chest/fly", "chest/press", "chest/cable-cross-over"])
        ]
    }

    ///
    /// Default exercise intensities that will be reported in case no models are found from the app
    ///
    internal var defaultIntensities: [MKIntensity] {
        return [
            MKIntensity(id: 1, title: "Easy",      restDuration: 240, heartRateRange: (0.0,  0.4)),
            MKIntensity(id: 2, title: "Moderate",  restDuration: 120, heartRateRange: (0.4,  0.6)),
            MKIntensity(id: 3, title: "Hard",      restDuration: 60,  heartRateRange: (0.6,  0.75)),
            MKIntensity(id: 4, title: "Very hard", restDuration: 40,  heartRateRange: (0.75, 1.0))
        ]
    }
    
}
