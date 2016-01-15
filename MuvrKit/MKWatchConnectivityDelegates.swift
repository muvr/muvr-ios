import Foundation

///
/// Delegate to report on exercise session events received from the phone
///
public protocol MKExerciseSessionConnectivityDelegate {

    func sessionStarted(session: MKExerciseSession, props: MKExerciseSessionProperties)
    
    func sessionEnded(session: MKExerciseSession, props: MKExerciseSessionProperties)
    
}
