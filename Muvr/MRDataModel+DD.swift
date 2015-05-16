import Foundation
import SQLite

///
/// The data definition for resistance exercise session
///
extension MRDataModel.MRResistanceExerciseSessionDataModel {
    
    private static func createChild(t: SchemaBuilder) -> Void {
        let fk = MRDataModel.resistanceExerciseSessions.namespace(MRDataModel.rowId)
        t.column(MRDataModel.rowId, primaryKey: true)
        t.column(sessionId)
        t.column(MRDataModel.timestamp)
        t.column(MRDataModel.json)
        
        t.foreignKey(sessionId, references: fk, update: SchemaBuilder.Dependency.Restrict, delete: SchemaBuilder.Dependency.Cascade)
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
extension MRDataModel.MRMuscleGroupDataModel {
    
    private static func create(t: SchemaBuilder) -> Void {
        t.column(MRDataModel.locid, primaryKey: true)
        t.column(MRDataModel.json)
    }
    
}

extension MRDataModel.MRExerciseDataModel {

    private static func create(t: SchemaBuilder) -> Void {
        t.column(MRDataModel.locid, primaryKey: true)
        t.column(MRDataModel.json)
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
        
        let nums = split(version) { $0 == "." }
        assert(nums.count == 2)
        
        return 10 * nums[0].toInt()! + nums[1].toInt()!
    }
    
    internal static func create() -> CreateResult {
        func create() {
            database.create(table: resistanceExerciseSessions,    temporary: false, ifNotExists: true, MRDataModel.MRResistanceExerciseSessionDataModel.create)
            database.create(table: resistanceExerciseSets,        temporary: false, ifNotExists: true, MRDataModel.MRResistanceExerciseSessionDataModel.createChild)
            database.create(table: resistanceExerciseSetExamples, temporary: false, ifNotExists: true, MRDataModel.MRResistanceExerciseSessionDataModel.createChild)
            database.create(table: exercisePlanDeviations,        temporary: false, ifNotExists: true, MRDataModel.MRResistanceExerciseSessionDataModel.createChild)
            database.create(table: muscleGroups,                  temporary: false, ifNotExists: true, MRDataModel.MRMuscleGroupDataModel.create)
            database.create(table: exercises,                     temporary: false, ifNotExists: true, MRDataModel.MRExerciseDataModel.create)
            database.userVersion = version()
        }
        
        func drop() {
            database.drop(table: resistanceExerciseSets,        ifExists: true)
            database.drop(table: resistanceExerciseSetExamples, ifExists: true)
            database.drop(table: exercisePlanDeviations,        ifExists: true)
            database.drop(table: resistanceExerciseSessions,    ifExists: true)
            database.drop(index: exercises,                     ifExists: true)
            database.drop(index: muscleGroups,                  ifExists: true)
        }
        
        func setDefaultData() {
            if let exercises = loadArray("exercises", unmarshal: MRExercise.unmarshal) {
                MRDataModel.MRExerciseDataModel.set(exercises.1, locale: exercises.0)
            }
            if let muscleGroups = loadArray("musclegroups", unmarshal: MRMuscleGroup.unmarshal) {
                MRDataModel.MRMuscleGroupDataModel.set(muscleGroups.1, locale: muscleGroups.0)
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
