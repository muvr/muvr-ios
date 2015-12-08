import MuvrKit

///
/// Upload user sessions
///
class MRExerciseSessionStore {

    private var storageAccess: MRCloudStorageAccessProtocol
    
    init(storageAccess: MRCloudStorageAccessProtocol) {
        self.storageAccess = storageAccess
    }
    
    ///
    /// Upload a user session (json + csv files)
    ///
    func uploadSession(session: MRManagedExerciseSession, continuation: () -> Void) {
        var csvUploaded = false
        var jsonUploaded = false
        
        func checkCompletion() {
            if csvUploaded && jsonUploaded {
                continuation()
            }
        }
        
        // generate json file with session metadata and exercises
        let output = NSOutputStream.outputStreamToMemory()
        output.open()
        let error = NSErrorPointer()
        NSJSONSerialization.writeJSONObject(session.json, toStream: output, options: [], error: error)
        guard let jsonData = output.propertyForKey(NSStreamDataWrittenToMemoryStreamKey) as? NSData else { return }
        
        storageAccess.uploadFile("/sessions/\(session.id)_\(session.exerciseModelId).json", data: jsonData) {
            jsonUploaded = true
            checkCompletion()
        }
        
        // generate CSV file with sensor data
        guard let data = session.sensorData,
              let labelledExercises = session.labelledExercises.allObjects as? [MRManagedLabelledExercise],
              let sensorData = try? MKSensorData(decoding: data) else { return }
        let csvData = sensorData.encodeAsCsv(labelledExercises: labelledExercises)
        storageAccess.uploadFile("/sessions/\(session.id)_\(session.exerciseModelId).csv", data: csvData) {
            csvUploaded = true
            checkCompletion()
        }
    }
    
}

