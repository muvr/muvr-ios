import Foundation

// TODO: Match with CoreData
public protocol MKExerciseSessionStore {
    
    func getCurrentSession() -> MKExerciseSession?
        
    func getSessionById(id: String) -> MKExerciseSession?
    
    func getAllSessions() -> [MKExerciseSession]

    // func getSessionsOnDate(date: NSDate) -> [MKExerciseSession]
    
}
