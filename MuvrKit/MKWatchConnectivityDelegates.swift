import Foundation

///
/// Delegate that is typically used in the ``MRMetadataConnectivitySession`` to
/// report on the exercise metadata updates
///
public protocol MKExerciseSessionConnectivityDelegate {

    // TODO: send the exercise types here: the phone drives the ordering
    // func metadataConnectivityDidReceiveExerciseModelMetadata(modelMetadata: [MKExerciseModelMetadata])
    
    func sessionStarted(_ session: (MKExerciseSession, MKExerciseSessionProperties))
    func sessionEnded(_ session: (MKExerciseSession, MKExerciseSessionProperties))
    
}
