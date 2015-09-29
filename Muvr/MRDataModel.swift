//import Foundation
import SQLite
import SwiftyJSON
import MuvrKit

/// The session detail aggregate
struct MRResistanceExerciseSessionDetail<A> {
    var id: NSUUID
    var session: MRResistanceExerciseSession
    var details: [A]
}

///
/// Defines the persistence model, closely tied to SQLite (the framework and the underlying DB). This 
/// is in favour of CoreData in persuit of initial simplicity. It may be necessary to switch to using
/// CoreData if the SQLite approach becomes too cumbersome.
///
/// The storage model follows the Akka journal approach. Each persisted entry (living in its own table)
/// defines the identity, timestamp and the payload. Some tables include foreign key relationships to 
/// make the strucrue of the data explicit.
///
struct MRDataModel {
        
    /// The database instance
    internal static var database: Connection {
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        let dbPath = "\(path)/db.sqlite3"
        
        // NSFileManager.defaultManager().removeItemAtPath(dbPath, error: nil)
        return try! Connection(dbPath)
    }
        
    /// resistance exercise sessions table (1:N) to resistance exercise sets
    internal static let resistanceExerciseSessions = Table("resistanceExerciseSessions")
    /// resistance exercise examples table
    internal static let resistanceExerciseExamples = Table("resistanceExerciseExamples")
    /// the data for the examples
    internal static let resistanceExerciseExamplesData = Table("resistanceExerciseExamplesData")
    /// muscle groups
    internal static let exerciseModels = Table("exerciseModels")
    /// exercises
    internal static let exercises = Table("exercises")
    
    /// common identity column
    internal static let rowId = Expression<NSUUID>("id")
    /// common identity column
    internal static let serverId = Expression<NSUUID?>("serverId")
    /// common timestamp column
    internal static let timestamp = Expression<NSDate>("timestamp")
    /// common JSON column
    internal static let json = Expression<JSON>("json")
    /// the locale id
    internal static let locid = Expression<String>("locid")
    
    ///
    /// Muscle group data model
    ///
    struct MRExerciseModelDataModel {
        
        static func set(models: [MRExerciseModel]) {
            exerciseModels.delete()
            models.forEach {
                try! database.run(exerciseModels.insert(json <- JSON($0.marshal())))
            }
        }
        
        static func get() -> [MRExerciseModel] {
            var ms: [MRExerciseModel] = []
            for row in database.prepare(exerciseModels) {//.filter(locid == locale.localeIdentifier) {
                ms.append(MRExerciseModel.unmarshal(row.get(json)))
            }
            return ms
        }
        
    }
    
    ///
    /// Exercise data model
    ///
    struct MRExerciseDataModel {
        typealias ExerciseLocalisation = (String, String)
        static var cache: [String:[ExerciseLocalisation]] = [:]
        static let exerciseId = Expression<String>("exerciseId")
        static let title      = Expression<String>("title")

        static func set(values: [ExerciseLocalisation], locale: NSLocale) {
            let l = locale.localeIdentifier
            exercises.filter(locid == l).delete()
            values.forEach { x in
                try! database.run(exercises.insert(locid <- l, exerciseId <- x.0, title <- x.1))
            }
            cache[locale.localeIdentifier] = values
        }
        
        static func get(locale: NSLocale) -> [(String, String)] {
            if let v = cache[locale.localeIdentifier] { return v }
            
            var exs: [ExerciseLocalisation] = []
            for row in database.prepare(exercises) {//.filter(locid == locale.localeIdentifier) {
                exs.append((row.get(exerciseId), row.get(title)))
            }
            cache[locale.localeIdentifier] = exs
            return exs
        }
    }
    
    ///
    /// The exercise session
    ///
    struct MRResistanceExerciseSessionDataModel {
        static let deleted = Expression<Bool>("deleted")
        static let sessionId = Expression<NSUUID>("sessionId")
        static let exampleId = Expression<NSUUID>("exampleId")
        static let fusedSensorData = Expression<NSData>("fusedSensorData")

        /// Finds all MRResistanceExerciseSession instances
        static func findAll(limit: Int = 100) -> [MRResistanceExerciseSession] {
            // select * from resistanceExerciseSessions order by timestamp
            var sessions: [MRResistanceExerciseSession] = []

            let q = resistanceExerciseSessions.select(json).filter(deleted == false).order(timestamp.desc).limit(limit)
            for row in database.prepare(q) {
                sessions += [MRResistanceExerciseSession.unmarshal(row.get(json))]
            }
            return sessions
        }
        
        private static func mapDetail<A>(query: QueryType, mapper: Row -> (NSUUID, MRResistanceExerciseSession, A)) -> [MRResistanceExerciseSessionDetail<A>] {
            var r: [MRResistanceExerciseSessionDetail<A>] = []
            for row in database.prepare(query) {
                let (id, session, detail) = mapper(row)
                if let last = r.last {
                    if id != last.id {
                        r.append(MRResistanceExerciseSessionDetail(id: id, session: session, details: [detail]))
                    } else {
                        r.removeLast()
                        r.append(MRResistanceExerciseSessionDetail(id: id, session: session, details: last.details + [detail]))
                    }
                } else {
                    r.append(MRResistanceExerciseSessionDetail(id: id, session: session, details: [detail]))
                }
                    
            }
            return r
        }
        
        /// Finds all MRResistanceExerciseSessionDetails on the given date
        static func find(on date: NSDate) -> [MRResistanceExerciseSessionDetail<MRResistanceExerciseExample>] {
            let midnight = date.dateOnly
            let query = resistanceExerciseSessions
                .join(resistanceExerciseExamples, on: sessionId == resistanceExerciseSessions.namespace(rowId))
                .filter(deleted == false &&
                        resistanceExerciseSessions.namespace(timestamp) >= midnight && resistanceExerciseSessions.namespace(timestamp) < midnight.addDays(1))
                .order(resistanceExerciseSessions.namespace(timestamp).desc)
                .select(resistanceExerciseSessions.namespace(rowId), resistanceExerciseSessions.namespace(json), resistanceExerciseExamples.namespace(json))
            return mapDetail(query) { row in
                return (
                    row.get(resistanceExerciseSessions.namespace(rowId)),
                    MRResistanceExerciseSession.unmarshal(row.get(resistanceExerciseSessions.namespace(json))),
                    MRResistanceExerciseExample.unmarshal(row.get(resistanceExerciseExamples.namespace(json)))
                )
            }
        }
        
        /// Finds all unsynchronized details
        static func findUnsynced() -> [MRResistanceExerciseSessionDetail<(MRResistanceExerciseExample, NSData)>] {
            let query = resistanceExerciseSessions
                .join(resistanceExerciseExamples, on: sessionId == resistanceExerciseSessions.namespace(rowId))
                .join(resistanceExerciseExamplesData, on: exampleId == resistanceExerciseExamples.namespace(rowId))
                .filter(deleted == false && resistanceExerciseSessions.namespace(serverId) == nil)
                .order(resistanceExerciseSessions.namespace(timestamp).desc)
                .select(resistanceExerciseSessions.namespace(rowId), resistanceExerciseSessions.namespace(json), resistanceExerciseExamples.namespace(json), resistanceExerciseExamplesData.namespace(fusedSensorData))
            
            return mapDetail(query) { row in
                return (
                    row.get(resistanceExerciseSessions.namespace(rowId)),
                    MRResistanceExerciseSession.unmarshal(row.get(resistanceExerciseSessions.namespace(json))),
                    (
                        MRResistanceExerciseExample.unmarshal(row.get(resistanceExerciseExamples.namespace(json))),
                        row.get(resistanceExerciseExamplesData.namespace(self.fusedSensorData))
                    )
                )
            }
        }
        
        /// Removes all sessions and their sets
        static func deleteAll() -> Void {
            try! database.run(resistanceExerciseExamplesData.delete())
            try! database.run(resistanceExerciseExamples.delete())
            try! database.run(resistanceExerciseSessions.delete())
        }

        /// sets the server id value
        static func setSynchronised(id: NSUUID, serverId: NSUUID) -> Void {
            try! database.run(MRDataModel.resistanceExerciseSessions.filter(MRDataModel.rowId == id).update(MRDataModel.serverId <- serverId))
        }

        /// Inserts a new ``session`` with the given row ``id``
        static func insert(id: NSUUID, session: MRResistanceExerciseSession) -> Void {
            try! database.run(resistanceExerciseSessions.insert(rowId <- id, timestamp <- session.startDate, deleted <- false, json <- JSON(session.marshal())))
        }
        
        /// removes a row identified by row ``id``
        static func delete(id: NSUUID) -> Void {
            try! database.run(resistanceExerciseSessions.filter(rowId == id).limit(1).update(deleted <- true))
        }
        
        private static func findChildren<A>(from from: QueryType, sessionId: MRSessionId, unmarshal: JSON -> A) -> [A] {
            var r: [A] = []
            for row in database.prepare(from) {
                r.append(unmarshal(row.get(json)))
            }
            return r
        }
        
        /// add an example to this session
        static func insertResistanceExerciseExample(id: NSUUID, sessionId: NSUUID, example: MRResistanceExerciseExample, fusedSensorData: NSData) -> Void{
            try! database.run(MRDataModel.resistanceExerciseExamples.insert(rowId <- id, self.sessionId <- sessionId, json <- JSON(example.marshal())))
            try! database.run(MRDataModel.resistanceExerciseExamplesData.insert(rowId <- id, exampleId <- id, self.fusedSensorData <- fusedSensorData))
        }
        
        /// find the EES as array of JSONs to be synchronized
        static func findResistanceExerciseExamplesJson(sessionId: MRSessionId) -> [JSON] {
            return findChildren(from: MRDataModel.resistanceExerciseExamples, sessionId: sessionId, unmarshal: identity)
        }
        
    }
    
}
