import Foundation

///
/// Implementations will receive the results of session classification and summarisation
///
public protocol MKSessionClassifierDelegate {
    
    ///
    /// Called when the session classification completes. The session continues even
    /// after the classification.
    ///
    /// - parameter session: the current snapshot of the session
    ///
    func sessionClassifierDidClassify(session: MKExerciseSession)
    
    ///
    /// Called when the session classification completes. The session will no longer
    /// change after this call
    ///
    /// - parameter session: the current snapshot of the session
    ///
    func sessionClassifierDidSummarise(session: MKExerciseSession)
    
    ///
    /// Called when the session starts
    ///
    /// - parameter session: the session that has just started
    ///
    func sessionClassifierDidStart(session: MKExerciseSession)
    
}