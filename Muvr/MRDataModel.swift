//import Foundation
import SQLite

/// The session detail aggregate
typealias MRResistanceExerciseSessionDetail = ((NSUUID, MRResistanceExerciseSession), [MRClassifiedResistanceExercise])

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
    internal static var database: Database {
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first as! String
        let db = Database("\(path)/db.sqlite3")
        db.foreignKeys = true
        return db
    }
        
    /// resistance exercise sessions table (1:N) to resistance exercise sets
    internal static let resistanceExerciseSessions = database["resistanceExerciseSessions"]
    /// resistance exercise sets table
    internal static let resistanceExercises = database["resistanceExercises"]
    /// resistance exercise examples table
    internal static let resistanceExerciseExamples = database["resistanceExerciseExamples"]
    /// muscle groups
    internal static let exerciseModels = database["exerciseModels"]
    /// exercises
    internal static let exercises = database["exercises"]
    
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
        
        static func set(groups: [MRExerciseModel]) {
            exerciseModels.delete()
            groups.forEach { exerciseModels.insert(json <- JSON($0.marshal())) }
        }
        
        static func get() -> [MRExerciseModel] {
            var mgs: [MRExerciseModel] = []
            for row in exerciseModels {//.filter(locid == locale.localeIdentifier) {
                mgs += [MRExerciseModel.unmarshal(row.get(json))]
            }
            return mgs
        }
        
    }
    
    ///
    /// Exercise data model
    ///
    struct MRResistanceExerciseDataModel {

        static func set(values: [MRResistanceExercise], locale: NSLocale) {
            let l = locale.localeIdentifier
            exercises.filter(locid == l).delete()
            exercises.insert(locid <- l, json <- JSON(values.map { $0.marshal() }))
        }
        
        static func get(locale: NSLocale) -> [MRResistanceExercise] {
            var exs: [MRResistanceExercise] = []
            for row in exercises {//.filter(locid == locale.localeIdentifier) {
                exs += row.get(json).arrayValue.map(MRResistanceExercise.unmarshal)
            }
            return exs
        }
    }
    
    ///
    /// The exercise session
    ///
    struct MRResistanceExerciseSessionDataModel {
        static let deleted = Expression<Bool>("deleted")
        static let sessionId = Expression<NSUUID>("sessionId")

        /// Finds all MRResistanceExerciseSession instances
        static func findAll(limit: Int = 100) -> [MRResistanceExerciseSession] {
            // select * from resistanceExerciseSessions order by timestamp
            var sessions: [MRResistanceExerciseSession] = []
            for row in resistanceExerciseSessions.filter(deleted == false).order(timestamp.desc).limit(limit) {
                sessions += [MRResistanceExerciseSession.unmarshal(row.get(json))]
            }
            return sessions
        }
        
        private static func mapDetail(query: Query) -> [MRResistanceExerciseSessionDetail] {
            func map(row: Row) -> (NSUUID, MRResistanceExerciseSession, MRClassifiedResistanceExercise) {
                return (
                    row.get(resistanceExerciseSessions.namespace(rowId)),
                    MRResistanceExerciseSession.unmarshal(row.get(resistanceExerciseSessions.namespace(json))),
                    MRClassifiedResistanceExercise.unmarshal(row.get(resistanceExercises.namespace(json)))
                )
            }
            
            var r: [MRResistanceExerciseSessionDetail] = []
            for row in query {
                let (id, session, set) = map(row)
                if var ((lastId, _), sets) = r.last {
                    if id != lastId {
                        r += [((id, session), [set])]
                    } else {
                        r.removeLast()
                        r += [((id, session), sets + [set])]
                    }
                } else {
                    r += [((id, session), [set])]
                }
                    
            }
            return r
        }
        
        /// Finds all MRResistanceExerciseSessionDetails on the given date
        static func find(on date: NSDate) -> [MRResistanceExerciseSessionDetail] {
            let midnight = date.dateOnly
            let query = resistanceExerciseSessions
                .join(resistanceExercises, on: sessionId == resistanceExerciseSessions.namespace(rowId))
                .filter(deleted == false &&
                        resistanceExerciseSessions.namespace(timestamp) >= midnight && resistanceExerciseSessions.namespace(timestamp) < midnight.addDays(1))
                .order(resistanceExerciseSessions.namespace(timestamp).desc)
            
            return mapDetail(query)
        }
        
        /// Finds all unsynchronized details
        static func findUnsynced() -> [MRResistanceExerciseSessionDetail] {
            let query = resistanceExerciseSessions
                .join(resistanceExercises, on: sessionId == resistanceExerciseSessions.namespace(rowId))
                .filter(deleted == false && resistanceExerciseSessions.namespace(serverId) == nil)
                .order(resistanceExerciseSessions.namespace(timestamp).desc)
            return mapDetail(query)
        }
        
        /// Removes all sessions and their sets
        static func deleteAll() -> Void {
            resistanceExercises.delete()
            resistanceExerciseSessions.delete()
        }

        /// sets the server id value
        static func setSynchronised(id: NSUUID, serverId: NSUUID) -> Void {
            MRDataModel.resistanceExerciseSessions.filter(MRDataModel.rowId == id).update(MRDataModel.serverId <- serverId)
        }

        /// Inserts a new ``session`` with the given row ``id``
        static func insert(id: NSUUID, session: MRResistanceExerciseSession) -> Void {
            resistanceExerciseSessions.insert(
                rowId <- id,
                timestamp <- session.startDate,
                deleted <- false,
                json <- JSON(session.marshal()))
        }
        
        /// removes a row identified by row ``id``
        static func delete(id: NSUUID) -> Void {
            resistanceExerciseSessions.filter(rowId == id).limit(1).update(deleted <- true)
        }
        
        private static func insertChild(#into: Query, id: NSUUID, sessionId: NSUUID, value: JSON) -> Void {
            into.insert(
                rowId <- id,
                timestamp <- NSDate(),
                self.sessionId <- sessionId,
                json <- value)
        }
        
        private static func findChildren<A>(#from: Query, sessionId: MRSessionId, unmarshal: JSON -> A) -> [A] {
            var r: [A] = []
            for row in from {
                r.append(unmarshal(row.get(json)))
            }
            return r
        }

        /// add a set into this session
        static func insertResistanceExercise(id: NSUUID, sessionId: NSUUID, exercise: MRResistanceExercise) -> Void {
            insertChild(into: MRDataModel.resistanceExercises, id: id, sessionId: sessionId, value: JSON(exercise.marshal()))
        }
        
        /// add an example to this session
        static func insertResistanceExerciseExample(id: NSUUID, sessionId: NSUUID, example: MRResistanceExerciseExample) -> Void{
            insertChild(into: MRDataModel.resistanceExerciseExamples, id: id, sessionId: sessionId, value: JSON(example.marshal()))
        }
        
        /// find the EES as array of JSONs to be synchronized
        static func findResistanceExerciseExamplesJson(sessionId: MRSessionId) -> [JSON] {
            return findChildren(from: MRDataModel.resistanceExerciseExamples, sessionId: sessionId, unmarshal: identity)
        }
        
    }
    
}
