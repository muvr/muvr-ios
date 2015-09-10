import Foundation
import SQLite

///
/// The data definition for resistance exercise session
///
extension MRDataModel.MRResistanceExerciseSessionDataModel {
    
    private static func createExamples(t: SchemaBuilder) -> Void {
        let fk = MRDataModel.resistanceExerciseSessions.namespace(MRDataModel.rowId)
        t.column(MRDataModel.rowId, primaryKey: true)
        t.column(sessionId)
        t.column(MRDataModel.json)
        
        t.foreignKey(sessionId, references: fk, update: SchemaBuilder.Dependency.Restrict, delete: SchemaBuilder.Dependency.Cascade)
    }
    
    private static func createExamplesData(t: SchemaBuilder) -> Void {
        let fk = MRDataModel.resistanceExerciseExamples.namespace(MRDataModel.rowId)
        t.column(MRDataModel.rowId, primaryKey: true)
        t.column(exampleId)
        t.column(fusedSensorData)
        
        t.foreignKey(exampleId, references: fk, update: SchemaBuilder.Dependency.Restrict, delete: SchemaBuilder.Dependency.Cascade)
    }

    private static func create(t: SchemaBuilder) -> Void {
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
    
    private static func create(t: SchemaBuilder) -> Void {
        t.column(MRDataModel.json)
    }
    
}

extension MRDataModel.MRExerciseDataModel {

    private static func create(t: SchemaBuilder) -> Void {
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
        case Recreated()
        case UpgradedFrom(version: String)
    }

    private static func version() -> Int {
        let dictionary = NSBundle.mainBundle().infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        
        let nums = version.characters.split { $0 == "." }.map { String($0) }
        assert(nums.count == 2)
        
        return 10 * Int(nums[0])! + Int(nums[1])!
    }
    
    internal static func create() -> CreateResult {
        func create() {
            database.create(table: resistanceExerciseSessions,    temporary: false, ifNotExists: true, MRDataModel.MRResistanceExerciseSessionDataModel.create)
            database.create(table: resistanceExerciseExamples,    temporary: false, ifNotExists: true, MRDataModel.MRResistanceExerciseSessionDataModel.createExamples)
            database.create(table: resistanceExerciseExamplesData,temporary: false, ifNotExists: true, MRDataModel.MRResistanceExerciseSessionDataModel.createExamplesData)
            database.create(table: exerciseModels,                temporary: false, ifNotExists: true, MRDataModel.MRExerciseModelDataModel.create)
            database.create(table: exercises,                     temporary: false, ifNotExists: true, MRDataModel.MRExerciseDataModel.create)
            database.userVersion = version()
        }
        
        func drop() {
            database.drop(table: resistanceExerciseExamplesData,ifExists: true)
            database.drop(table: resistanceExerciseExamples,    ifExists: true)
            database.drop(table: resistanceExerciseSessions,    ifExists: true)
            database.drop(index: exercises,                     ifExists: true)
            database.drop(index: exerciseModels,                ifExists: true)
        }
        
        func setDefaultData() {
            if let exerciseTitles = (loadArray("exercises") { json in return (json["id"].stringValue, json["title"].stringValue) }) {
                MRDataModel.MRExerciseDataModel.set(exerciseTitles.1, locale: exerciseTitles.0)
            }
            if let exerciseModels = loadArray("exercisemodels", unmarshal: MRExerciseModel.unmarshal) {
                MRDataModel.MRExerciseModelDataModel.set(exerciseModels.1)
            }
        }
        
        let needsUpgrade = database.userVersion < version() && database.userVersion > 0
        
        if needsUpgrade {
            drop()
            create()
            setDefaultData()
            return .Recreated()
        }
        create()
        setDefaultData()
        return .Created()
    }
    
}
