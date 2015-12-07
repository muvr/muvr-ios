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
    func listModels(contination: [MRExerciseModel] -> Void) {
        storageAccess.listFiles("/models") { urls in
            guard let urls = urls else { return }
            let models = MRExerciseModel.latestModels(urls)
            contination(Array(models.values))
        }
    }
    
    ///
    /// download a given model
    ///
    func downloadModel(model: MRExerciseModel, continuation: MRExerciseModel -> Void) {
        guard model.isComplete() else { return }
        
        var abort: Bool = false
        var weightsUrl: NSURL? = nil
        var layersUrl: NSURL? = nil
        var labelsUrl: NSURL? = nil
        
        func processData(url: NSURL, data: NSData?) -> NSURL? {
            guard let data = data, let filename = url.lastPathComponent where !abort else {
                abort = true
                cleanupTmpFiles([weightsUrl, layersUrl, labelsUrl].flatMap { return $0 } )
                return nil
            }
            return saveIntoTmpFile(filename, data: data)
        }
        
        func checkCompletion() {
            guard let weightsUrl = weightsUrl,
                  let layersUrl = layersUrl,
                  let labelsUrl = labelsUrl where !abort else { return }
            let newModel = MRExerciseModel(id: model.id, version: model.version, labels: labelsUrl, layers: layersUrl, weights: weightsUrl)
            continuation(newModel)
        }
        
        storageAccess.downloadFile(model.weights!) { data in
            weightsUrl = processData(model.weights!, data: data)
            checkCompletion()
        }
        
        storageAccess.downloadFile(model.layers!) { data in
            layersUrl = processData(model.layers!, data: data)
            checkCompletion()
        }
        
        storageAccess.downloadFile(model.labels!) { data in
            labelsUrl = processData(model.labels!, data: data)
            checkCompletion()
        }
    }
    
    private func cleanupTmpFiles(files: [NSURL]) {
        let fileManager = NSFileManager.defaultManager()
        for file in files {
            do {
                try fileManager.removeItemAtURL(file)
            } catch {
                // keep going
            }
        }
    }
    
    private func saveIntoTmpFile(filename: String, data: NSData) -> NSURL? {
        let fileManager = NSFileManager.defaultManager()
        guard let tmpDir = fileManager.URLsForDirectory(NSSearchPathDirectory.DownloadsDirectory, inDomains: .UserDomainMask).first
            else { return nil }
        let url = tmpDir.URLByAppendingPathComponent(filename, isDirectory: false)
        data.writeToURL(url, atomically: true)
        return url
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
        
        storageAccess.uploadFile("/test/\(session.id)_\(session.exerciseModelId).json", data: jsonData) {
            jsonUploaded = true
            checkCompletion()
        }
        
        // generate CSV file with sensor data
        guard let data = session.sensorData,
              let labelledExercises = session.labelledExercises.allObjects as? [MRManagedLabelledExercise],
              let sensorData = try? MKSensorData(decoding: data) else { return }
        let csvData = sensorData.encodeAsCsv(labelledExercises: labelledExercises)
        storageAccess.uploadFile("/test/\(session.id)_\(session.exerciseModelId).csv", data: csvData) {
            csvUploaded = true
            checkCompletion()
        }
    }
    
}

