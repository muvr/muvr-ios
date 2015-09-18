import Foundation
import SQLite

///
/// The data definition for resistance exercise session
///
extension MRDataModel.MRResistanceExerciseSessionDataModel {
    
    private static func createExamples(t: TableBuilder) -> Void {
        let fk = MRDataModel.resistanceExerciseSessions.namespace(MRDataModel.rowId)
        t.column(MRDataModel.rowId, primaryKey: true)
        t.column(sessionId)
        t.column(MRDataModel.json)

        //t.foreignKey(sessionId, references: fk, other: MRDataModel.resistanceExerciseSessions, update: TableBuilder.Dependency.Restrict, delete: TableBuilder.Dependency.Cascade)
    }
    
    private static func createExamplesData(t: TableBuilder) -> Void {
        let fk = MRDataModel.resistanceExerciseExamples.namespace(MRDataModel.rowId)
        t.column(MRDataModel.rowId, primaryKey: true)
        t.column(exampleId)
        t.column(fusedSensorData)
        
        //t.foreignKey(exampleId, references: fk, update: TableBuilder.Dependency.Restrict, delete: TableBuilder.Dependency.Cascade)
    }

    private static func create(t: TableBuilder) -> Void {
        t.column(MRDataModel.rowId, primaryKey: true)
        t.column(MRDataModel.serverId)
        t.column(MRDataModel.timestamp)
        t.column(MRDataModel.json)
        t.column(deleted)
    }
    
}

///
/// The data definition for muscle groups
///
extension MRDataModel.MRExerciseModelDataModel {
    
    private static func create(t: TableBuilder) -> Void {
        t.column(MRDataModel.json)
    }
    
}

extension MRDataModel.MRExerciseDataModel {

    private static func create(t: TableBuilder) -> Void {
        t.column(MRDataModel.locid)
        t.column(MRDataModel.MRExerciseDataModel.exerciseId)
        t.column(MRDataModel.MRExerciseDataModel.title)
    }

}

///
/// The data definition for the entire DB
///
extension MRDataModel {
    
    enum CreateResult {
        case Created()
        case Migrated(from: Int64)
        case NotChanged()
    }

    private static func version() -> Int64 {
        let dictionary = NSBundle.mainBundle().infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        
        let nums = version.characters.split { $0 == "." }.map { String($0) }
        assert(nums.count == 2)
        
        return 10 * Int64(nums[0])! + Int64(nums[1])!
    }
    
    internal static func create() -> CreateResult {
        func create(schemaVersion: Int64) {
            try! database.run(resistanceExerciseSessions.create(ifNotExists: true, block: MRDataModel.MRResistanceExerciseSessionDataModel.create))
            try! database.run(resistanceExerciseExamples.create(ifNotExists: true, block: MRDataModel.MRResistanceExerciseSessionDataModel.createExamples))
            try! database.run(resistanceExerciseExamplesData.create(ifNotExists: true, block: MRDataModel.MRResistanceExerciseSessionDataModel.createExamplesData))
            
            try! database.run(exercises.create(ifNotExists: true, block: MRDataModel.MRExerciseDataModel.create))
            
            createExerciseModelDB()
            
            try! database.run("PRAGMA schema_version = \(schemaVersion)")
        }
        
        func createExerciseModelDB() {
            try! database.run(exerciseModels.create(ifNotExists: true, block: MRDataModel.MRExerciseModelDataModel.create))
        }
        
        func drop() {
            try! database.run(resistanceExerciseExamplesData.drop(ifExists: true))
            try! database.run(resistanceExerciseExamples.drop(ifExists: true))
            try! database.run(resistanceExerciseSessions.drop(ifExists: true))
            
            try! database.run(exercises.drop(ifExists: true))
            dropExerciseModels()
        }
        
        func dropExerciseModels() {
            try! database.run(exerciseModels.drop(ifExists: true))
        }
        
        func setDefaultData() {
            setDefaultExerciseTitles()
            setDefaultExerciseModels()
        }
        
        func setDefaultExerciseTitles(){
            if let exerciseTitles = (loadArray("exercises") { json in return (json["id"].stringValue, json["title"].stringValue) }) {
                MRDataModel.MRExerciseDataModel.set(exerciseTitles.1, locale: exerciseTitles.0)
            }
        }
        
        func setDefaultExerciseModels(){
            if let exerciseModels = loadArray("exercisemodels", unmarshal: MRExerciseModel.unmarshal) {
                MRDataModel.MRExerciseModelDataModel.set(exerciseModels.1)
            }
        }
        
        let existingSchemaVersion = database.scalar("PRAGMA schema_version") as! Int64
        let expectedSchemaVersion = version()
        
        if existingSchemaVersion == 0 {
            // empty
            create(expectedSchemaVersion)
            setDefaultData()
            return .Created()
        } else if expectedSchemaVersion > existingSchemaVersion {
            // old version => migrate
            drop()
            create(expectedSchemaVersion)
            setDefaultData()
            return .Migrated(from: existingSchemaVersion)
        } else {
            // Lets make sure the label mapping of the model always fits!
            dropExerciseModels()
            createExerciseModelDB()
            setDefaultExerciseModels()
            // current version
            return .NotChanged()
        }
    }
    
}
