import Foundation

// TODO: Match with CoreData
public protocol MKExerciseSessionStore {
    
    func getCurrentSession() -> MKExerciseSession?
        
    func getAllSessions() -> [MKExerciseSession]
    
}
