import Foundation
import SQLite

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
    private static var database: Database {
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first as! String
        let db = Database("\(path)/db.sqlite3")
        MRDataModel.create(db)
        return db
    }
    /// resistance exercise sessions table (1:N) to resistance exercise sets
    static let resistanceExerciseSessions = database["resistanceExerciseSessions"]
    /// resistance exercise sets table
    static let resistanceExerciseSets = database["resistanceExerciseSets"]
    
    /// common identity column
    private static let id = Expression<NSUUID>("id")
    /// common identity column
    private static let serverId = Expression<NSUUID?>("serverId")
    /// common timestamp column
    private static let timestamp = Expression<NSDate>("timestamp")
    /// common JSON column
    private static let json = Expression<JSON>("json")

    ///
    /// The exercise session
    ///
    struct MRResistanceExerciseSessionDataModel {
        static let id = MRDataModel.id
        static let timestamp = MRDataModel.timestamp
        static let json = MRDataModel.json
        static let serverId = MRDataModel.serverId

        static func findAll(limit: Int = 100) -> [MRResistanceExerciseSession] {
            // select * from resistanceExerciseSessions order by timestamp
            var sessions: [MRResistanceExerciseSession] = []
            for row in resistanceExerciseSessions.order(timestamp.desc).limit(limit) {
                sessions += [MRResistanceExerciseSession.unmarshal(row.get(json))]
            }
            return sessions
        }
    }
    
    ///
    /// The exercise set, many sets in one session
    ///
    struct MRResistanceExerciseSetDataModel {
        static let id = MRDataModel.id
        static let sessionId = Expression<NSUUID>("sessionId")
        static let timestamp = MRDataModel.timestamp
        static let json = MRDataModel.json
        static let serverId = MRDataModel.serverId
    }
    
}

