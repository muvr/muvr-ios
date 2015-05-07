import Foundation
import SQLite

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
    
    /// common identity column
    internal static let rowId = Expression<NSUUID>("id")
    /// common identity column
    internal static let serverId = Expression<NSUUID?>("serverId")
    /// common timestamp column
    internal static let timestamp = Expression<NSDate>("timestamp")
    /// common JSON column
    internal static let json = Expression<JSON>("json")

    ///
    /// The exercise session
    ///
    struct MRResistanceExerciseSessionDataModel {

        static func findAll(limit: Int = 100) -> [MRResistanceExerciseSession] {
            // select * from resistanceExerciseSessions order by timestamp
            var sessions: [MRResistanceExerciseSession] = []
            for row in resistanceExerciseSessions.order(timestamp.desc).limit(limit) {
                sessions += [MRResistanceExerciseSession.unmarshal(row.get(json))]
            }
            return sessions
        }
        
        static func find(on date: NSDate) -> [MRResistanceExerciseSessionDetail] {
            
            func map(row: Row) -> (NSUUID, MRResistanceExerciseSession, MRResistanceExerciseSet) {
                return (
                    row.get(resistanceExerciseSessions.namespace(rowId)),
                    MRResistanceExerciseSession.unmarshal(row.get(resistanceExerciseSessions.namespace(json))),
                    MRResistanceExerciseSet.unmarshal(row.get(resistanceExerciseSets.namespace(json)))
                )
            }
            
            var r: [MRResistanceExerciseSessionDetail] = []

            let midnight = date.dateOnly
            for row in resistanceExerciseSessions
                .join(resistanceExerciseSets, on: MRResistanceExerciseSetDataModel.sessionId == resistanceExerciseSessions.namespace(rowId))
                .filter(resistanceExerciseSessions.namespace(timestamp) >= midnight && resistanceExerciseSessions.namespace(timestamp) < midnight.addDays(1))
                .order(resistanceExerciseSessions.namespace(rowId), resistanceExerciseSessions.namespace(timestamp).desc) {
            
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

        static func insert(id: NSUUID, session: MRResistanceExerciseSession) -> Void {
            resistanceExerciseSessions.insert(
                rowId <- id,
                timestamp <- session.startDate,
                json <- JSON(session.marshal()))
        }
        
    }
    
    ///
    /// The exercise set, many sets in one session
    ///
    struct MRResistanceExerciseSetDataModel {
        static let sessionId = Expression<NSUUID>("sessionId")
        
//        static func find(on date: NSDate) -> [MRResistanceExerciseSet] {
//            let midnight = date.dateOnly
//            var sets: [MRResistanceExerciseSet] = []
//            for row in resistanceExerciseSets.filter(timestamp > midnight.addDays(-1) && timestamp < midnight.addDays(1)) {
//                sets += [MRResistanceExerciseSet.unmarshal(row.get(json))]
//            }
//            return sets
//        }
        
        static func insert(id: NSUUID, sessionId: NSUUID, set: MRResistanceExerciseSet) -> Void {
            resistanceExerciseSets.insert(
                rowId <- id,
                timestamp <- NSDate(),
                self.sessionId <- sessionId,
                json <- JSON(set.marshal()))
        }
    }
    
}

