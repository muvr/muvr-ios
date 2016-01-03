import Foundation

///
/// Provides hint to the classification pipeline
///
public enum MKClassificationHint {
    
    ///
    /// The user has confirmed that he or she is definitely doing some exercise by interacting
    /// with the app or wearable.
    ///
    /// The _start_ interval must be set, the _end_ interval must be set when it
    /// becomes known; in other words, an exercise in progress will have ``nil`` end.
    ///
    /// - parameter start: the start offset
    /// - parameter duration: the duration
    /// - parameter expectedExercises: the exercises the user is likely to be performing
    ///
    case ExplicitExercise(start: NSTimeInterval, duration: NSTimeInterval?, expectedExercises: [MKExercise])
    
    ///
    /// The user is expected to be resting
    ///
    /// The _start_ interval must be set, the _end_ interval must be set when it
    /// becomes known; in other words, an exercise in progress will have ``nil`` end.
    ///
    /// - parameter start: the start offset
    /// - parameter duration: the duration
    ///
    case TooMuchRest(start: NSTimeInterval, duration: NSTimeInterval?)
    
    /// The start timestamp
    var start: NSTimeInterval {
        switch self {
        case .TooMuchRest(let start, _): return start
        case .ExplicitExercise(let start, _, _): return start
        }
    }
    
    /// The duration
    var duration: NSTimeInterval? {
        switch self {
        case .TooMuchRest(_, let duration): return duration
        case .ExplicitExercise(_, let duration, _): return duration
        }
    }
    
}

///
/// Provides a way for the container to provide hints to the classifier. The hints are
/// whether the user is exercising or not and what the suggested next exercises are.
///
public protocol MKClassificationHintSource {
    
    /// The list of known exercise periods (start, duration, suggestions); the classifier
    /// may use this information to skip exercise vs. no exercise detection and to
    /// make better predictions using the suggestions.
    var exercisingHints: [MKClassificationHint]? { get }
    
}

enum MKSensorDataSplit {
    
    ///
    /// This split contains explicitly marked exercise from the provided ``hint``.
    /// - parameter startOffset: the offset to the start of the ``data``
    /// - parameter data: the split
    /// - parameter hint: the user-provided hint
    ///
    case Hinted(startOffset: NSTimeInterval, data: MKSensorData, hint: MKClassificationHint)
    
    ///
    /// Contains automatically determined exercise regions.
    /// - parameter startOffset: the offset to the start of the ``data``
    /// - parameter data: the data that should contain exercise
    ///
    case Automatic(startOffset: NSTimeInterval, data: MKSensorData)
    
    /// The end
    var end: NSTimeInterval {
        switch self {
        case .Hinted(_, let data, _): return data.end
        case .Automatic(_, let data): return data.end
        }
    }
    
}

public class MKSensorDataSplitter {
    public let hintSource: MKClassificationHintSource!
    
    typealias Split = ([MKSensorDataSplit], [MKSensorDataSplit], NSTimeInterval)
    
    private let eneClassifier: MKClassifier

    public init(exerciseModelSource: MKExerciseModelSource, hintSource: MKClassificationHintSource) {
        self.hintSource = hintSource
        let slackingModel = try! exerciseModelSource.getExerciseModel(id: "slacking")
        eneClassifier = try! MKClassifier(model: slackingModel)
    }
    
    /*
private func classify(exerciseModelId exerciseModelId: MKExerciseModelId, sensorData: MKSensorData) -> [MKClassifiedExercise]? {
do {
let exerciseModel = try exerciseModelSource.getExerciseModel(id: exerciseModelId)
let exerciseClassifier = try MKClassifier(model: exerciseModel)

let results = try eneClassifier.classify(block: sensorData, maxResults: 2)
NSLog("Exercise / no exercise \(results)")
return try results.flatMap { result -> [MKClassifiedExercise] in
if result.exerciseId == "E" && result.duration >= exerciseModel.minimumDuration {
// this is an exercise block - get the corresponding data section
let data = try sensorData.slice(result.offset, duration: result.duration)
// classify the exercises in this block
let exercises = try! exerciseClassifier.classify(block: data, maxResults: 10)
// adjust the offset with the offset from the original block
// the offset returned by the classifier is relative to the current exercise block
let (repetitions, _) = try self.repetitionEstimator.estimate(data: data)
return exercises.map(self.shiftOffset(result.offset)).map(self.updateRepetitions(repetitions))
} else {
return []
}
}
} catch let ex {
NSLog("Failed to classify block: \(ex)")
return []
}
}
*/

    private func hintedSplit(from: NSTimeInterval, data: MKSensorData, hints: [MKClassificationHint]) -> Split {
        // first, filter hints that appear after ``from``
        let applicableHints = hints.filter { $0.start >= from }
        
        let completed: [MKSensorDataSplit] = applicableHints.filter { $0.duration != nil }.flatMap { hint in
            return try? .Hinted(startOffset: hint.start, data: data.slice(hint.start, duration: hint.duration!), hint: hint)
        }
        let partial: [MKSensorDataSplit] = applicableHints.filter { $0.duration == nil }.flatMap { hint in
            return try? .Hinted(startOffset: hint.start, data: data.slice(hint.start, duration: data.duration - hint.start), hint: hint)
        }
        let lastCompleted = completed.maxElement { l, r in l.end < r.end }?.end ?? from
        
        return (completed, partial, lastCompleted)
    }

    private func automatedSplit(from: NSTimeInterval, data: MKSensorData) -> Split {
        return ([], [], from + data.duration)
    }

    func split(from from: NSTimeInterval, data: MKSensorData) -> Split {
        if let hints = hintSource.exercisingHints {
            return hintedSplit(from, data: data, hints: hints)
        } else {
            return automatedSplit(from, data: data)
        }
    }
    
}