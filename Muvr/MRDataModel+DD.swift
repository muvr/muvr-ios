import Foundation
import SQLite

///
/// The data definition for resistance exercise set
///
extension MRDataModel.MRResistanceExerciseSetDataModel {

    private static func create(t: SchemaBuilder) -> Void {
        let fk = MRDataModel.resistanceExerciseSessions.namespace(MRDataModel.MRResistanceExerciseSessionDataModel.id)
        t.primaryKey(id)
        t.column(serverId)
        t.foreignKey(sessionId, references: fk, update: SchemaBuilder.Dependency.Restrict, delete: SchemaBuilder.Dependency.Cascade)
        t.column(timestamp)
        t.column(json)
    }
    
}

///
/// The data definition for resistance exercise session
///
extension MRDataModel.MRResistanceExerciseSessionDataModel {
    private static func create(t: SchemaBuilder) -> Void {
        t.primaryKey(id)
        t.column(serverId)
        t.column(timestamp)
        t.column(json)
    }
    
}

///
/// The data definition for the entire DB
///
extension MRDataModel {
    
    internal static func create(db: Database) -> Void {
        db.create(table: resistanceExerciseSessions, temporary: false, ifNotExists: true, MRDataModel.MRResistanceExerciseSessionDataModel.create)
        db.create(table: resistanceExerciseSets,     temporary: false, ifNotExists: true, MRDataModel.MRResistanceExerciseSetDataModel.create)
    }
    
}
