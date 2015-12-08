import MuvrKit

///
/// Load models from cloud storage
/// and upload user sessions
///
class MRCloudStorage {

    private var storageAccess: MRCloudStorageAccessProtocol
    
    init(storageAccess: MRCloudStorageAccessProtocol) {
        self.storageAccess = storageAccess
    }
    
    ///
    /// list models remotely available
    ///
    func listModels(continuation: [MRExerciseModel]? -> Void) {
        storageAccess.listFiles("/models/") { urls in
            guard let urls = urls else {
                continuation(nil)
                return
            }
            let models = MRExerciseModel.latestModels(urls)
            continuation(Array(models.values))
        }
    }
    
    ///
    /// download a given model
    ///
    func downloadModel(model: MRExerciseModel, dest: NSURL, continuation: MRExerciseModel? -> Void) {
        guard model.isComplete else { return }
        
        let fileManager = NSFileManager.defaultManager()
        var downloaded = 0
        var newModel = MRExerciseModel(id: model.id, version: model.version)
        
        func checkCompletion() {
            downloaded += 1
            if downloaded == 3 {
                continuation(newModel)
            }
        }
        
        func processFile(src: NSURL?, filename: String?) -> NSURL? {
            guard let filename = filename, let src = src else { return nil }
            let destUrl = dest.URLByAppendingPathComponent(filename)
            do {
                try fileManager.moveItemAtURL(src, toURL: destUrl)
                return destUrl
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
        NSJSONSerialization.writeJSONObject(session.toJson(), toStream: output, options: [], error: error)
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

