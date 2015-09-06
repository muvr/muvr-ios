import Foundation

extension MRDataModel {
    
    /// Data cleanup
    static func cleanup() {
        // (1) Remove exercise sessions without sets
        MRDataModel.database.execute("DELETE FROM resistanceExerciseSessions WHERE (SELECT COUNT(id) FROM resistanceExerciseExamples WHERE sessionId = resistanceExerciseSessions.id) = 0");
    }
    
}