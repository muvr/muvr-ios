import Foundation

///
/// Delegate that is typically used in the ``MRMetadataConnectivitySession`` to
/// report on the exercise metadata updates
///
public protocol MKMetadataConnectivityDelegate {

    ///
    /// Called when the application receives new exercise models
    ///
    /// - parameter models: the new models
    ///
    func metadataConnectivityDidReceiveExerciseModels(models: [MKExerciseModel])
    
    ///
    /// Called when the application receives new intensities
    ///
    /// - parameter intensities: the new intensities
    ///
    func metadataConnectivityDidReceiveIntensities(intensities: [MKIntensity])
    
}

///
/// Delegate that is typically used in the ``MRSensorDataConnectivitySession`` to
/// control the sensor data flow
///
public protocol MKSensorDataConnectivityDelegate: class {
 
    func sensorDataConnectivityPause()
    
    func sensorDataConnectivityBegin(samplingFrequency: UInt)
    
    func sensorDataConnectivityEnd()
    
}