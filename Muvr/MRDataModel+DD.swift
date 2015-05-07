import Foundation
import SQLite

///
/// The data definition for resistance exercise set
///
extension MRDataModel.MRResistanceExerciseSetDataModel {

    private static func create(t: SchemaBuilder) -> Void {
        let fk = MRDataModel.resistanceExerciseSessions.namespace(MRDataModel.rowId)
        t.column(MRDataModel.rowId, primaryKey: true)
        t.column(MRDataModel.serverId)
        t.column(sessionId)
        t.column(MRDataModel.timestamp)
        t.column(MRDataModel.json)

        t.foreignKey(sessionId, references: fk, update: SchemaBuilder.Dependency.Restrict, delete: SchemaBuilder.Dependency.Cascade)
    }
    
}

///
/// The data definition for resistance exercise session
///
extension MRDataModel.MRResistanceExerciseSessionDataModel {
    private static func create(t: SchemaBuilder) -> Void {
        t.column(MRDataModel.rowId, primaryKey: true)
        t.column(MRDataModel.serverId)
        t.column(MRDataModel.timestamp)
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
            database.create(table: resistanceExerciseSessions, temporary: false, ifNotExists: true, MRDataModel.MRResistanceExerciseSessionDataModel.create)
            database.create(table: resistanceExerciseSets,     temporary: false, ifNotExists: true, MRDataModel.MRResistanceExerciseSetDataModel.create)
            database.userVersion = version()
        }
        
        func drop() {
            database.drop(table: resistanceExerciseSets,     ifExists: true)
            database.drop(table: resistanceExerciseSessions, ifExists: true)
        }
        
        let needsUpgrade = database.userVersion < version() && database.userVersion > 0
        
        if needsUpgrade {
            drop()
            create()
            return .Recreated()
        }
        create()
        return .Created()
    }
    
}
