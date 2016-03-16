import MuvrKit

typealias MRAchievement = String

///
/// Decides if the user deserves an achievement for his workouts
///
class MRSessionAppraiser {
    
    ///
    /// Decides if the user deserves an achievement for the given sessions
    /// - parameter sessions: the user sessions of the same workout
    /// - returns the achievement or nil
    ///
    func achievementForSessions(sessions: [MRManagedExerciseSession], plan: MKExercisePlan) -> MRAchievement? {
        let validSessions = sessions.filter { plan.id == $0.plan.templateId ?? "" }
        if validSessions.count >= 2 {
            return "star" // well done, 1 star
        }
        return nil
    }
    
}