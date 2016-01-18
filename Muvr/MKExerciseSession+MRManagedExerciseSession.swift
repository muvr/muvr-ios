import MuvrKit

extension MKExerciseSession {

    init(managedSession session: MRManagedExerciseSession) {
        self.init(
            id: session.id!,
            start: session.start,
            end: session.end,
            completed: session.completed,
            exerciseType: session.exerciseType
        )
    }
    
}
