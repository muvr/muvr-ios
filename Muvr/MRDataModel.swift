import Foundation
import SQLite

/// The session detail aggregate
typealias MRResistanceExerciseSessionDetail = ((NSUUID, MRResistanceExerciseSession), [MRResistanceExerciseSet])

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
    internal static let resistanceExerciseSets = database["resistanceExerciseSets"]
    /// resistance exercise examples table
    internal static let resistanceExerciseSetExamples = database["resistanceExerciseSetExamples"]
    /// plan deviations
    internal static let exercisePlanDeviations = database["exercisePlanDeviations"]
    /// muscle groups
    internal static let muscleGroups = database["muscleGroups"]
    /// exercises
    internal static let exercises = database["exercises"]
    /// exercise plans
    internal static let exercisePlans = database["exercisePlan"]
    
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
    /// Resistance exercise plans
    ///
    struct MRResistanceExercisePlanDataModel {
        static let defaultPlans: [MRResistanceExercisePlan] = MRDataModel.loadArray("resistanceplans", unmarshal: MRResistanceExercisePlan.unmarshal)!.1
            
    }
    
    ///
    /// Muscle group data model
    ///
    struct MRMuscleGroupDataModel {
        
        static func set(groups: [MRMuscleGroup], locale: NSLocale) {
            let l = locale.localeIdentifier
            muscleGroups.filter(locid == l).delete()
            muscleGroups.insert(locid <- l, json <- JSON(groups.map { $0.marshal() }))
        }
        
        static func get(locale: NSLocale) -> [MRMuscleGroup] {
            var mgs: [MRMuscleGroup] = []
            for row in muscleGroups {//.filter(locid == locale.localeIdentifier) {
                mgs += row.get(json).arrayValue.map(MRMuscleGroup.unmarshal)
            }
            return mgs
        }
        
    }
    
    ///
    /// Exercise data model
    ///
    struct MRExerciseDataModel {

        static func set(values: [MRExercise], locale: NSLocale) {
            let l = locale.localeIdentifier
            exercises.filter(locid == l).delete()
            exercises.insert(locid <- l, json <- JSON(values.map { $0.marshal() }))
        }
        
        static func get(locale: NSLocale) -> [MRExercise] {
            var exs: [MRExercise] = []
            for row in exercises {//.filter(locid == locale.localeIdentifier) {
                exs += row.get(json).arrayValue.map(MRExercise.unmarshal)
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
            func map(row: Row) -> (NSUUID, MRResistanceExerciseSession, MRResistanceExerciseSet) {
                return (
                    row.get(resistanceExerciseSessions.namespace(rowId)),
                    MRResistanceExerciseSession.unmarshal(row.get(resistanceExerciseSessions.namespace(json))),
                    MRResistanceExerciseSet.unmarshal(row.get(resistanceExerciseSets.namespace(json)))
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
                .join(resistanceExerciseSets, on: sessionId == resistanceExerciseSessions.namespace(rowId))
                .filter(deleted == false &&
                        resistanceExerciseSessions.namespace(timestamp) >= midnight && resistanceExerciseSessions.namespace(timestamp) < midnight.addDays(1))
                .order(resistanceExerciseSessions.namespace(timestamp).desc)
            
            return mapDetail(query)
        }
        
        /// Finds all unsynchronized details
        static func findUnsynced() -> [MRResistanceExerciseSessionDetail] {
            let query = resistanceExerciseSessions
                .join(resistanceExerciseSets, on: sessionId == resistanceExerciseSessions.namespace(rowId))
                .filter(deleted == false && resistanceExerciseSessions.namespace(serverId) == nil)
                .order(resistanceExerciseSessions.namespace(timestamp).desc)
            return mapDetail(query)
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
        static func insertResistanceExerciseSet(id: NSUUID, sessionId: NSUUID, set: MRResistanceExerciseSet) -> Void {
            insertChild(into: MRDataModel.resistanceExerciseSets, id: id, sessionId: sessionId, value: JSON(set.marshal()))
        }
        
        /// add an example to this session
        static func insertResistanceExerciseSetExample(id: NSUUID, sessionId: NSUUID, example: MRResistanceExerciseSetExample) -> Void{
            insertChild(into: MRDataModel.resistanceExerciseSetExamples, id: id, sessionId: sessionId, value: JSON(example.marshal()))
        }
        
        /// add a plan deviation to this session
        static func insertExercisePlanDeviation(id: NSUUID, sessionId: NSUUID, deviation: MRExercisePlanDeviation) -> Void {
            insertChild(into: MRDataModel.exercisePlanDeviations, id: id, sessionId: sessionId, value: JSON(deviation.marshal()))
        }

        /// find the EES as array of JSONs to be synchronized
        static func findResistanceExerciseSetExamplesJson(sessionId: MRSessionId) -> [JSON] {
            return findChildren(from: MRDataModel.resistanceExerciseSetExamples, sessionId: sessionId, unmarshal: identity)
        }
        
        /// find the EPD as array of JSONs to be synchronized
        static func findExercisePlanDeviationsJson(sessionId: MRSessionId) -> [JSON] {
            return findChildren(from: MRDataModel.exercisePlanDeviations, sessionId: sessionId, unmarshal: identity)
        }
    }
    
}
