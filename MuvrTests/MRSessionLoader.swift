import Foundation
import MuvrKit
@testable import Muvr

struct MRLoadedSession {
    typealias Row = (MKExerciseDetail, [MKExerciseLabel])
    
    let description: String
    let rows: [Row]
    let exerciseType: MKExerciseType
}

class MRSessionLoader {
    private init() {
        
    }
    
    static func read(_ fileName: String, detail: (MKExercise.Id) -> MKExerciseDetail?) -> MRLoadedSession {
        
        func parseLabel(_ text: String) -> MKExerciseLabel? {
            let components = text.componentsSeparatedByString("=")
            if components.count != 2 { return nil }
            switch (components.first!.stringByTrimmingCharactersInSet(CharacterSet.whitespaceCharacterSet()), components.last!) {
            case ("R", let text): return Int(text).map { MKExerciseLabel.Repetitions(repetitions: $0) }
            case ("I", let text): return Double(text).map { MKExerciseLabel.Intensity(intensity: $0) }
            case ("W", let text): return Double(text).map { MKExerciseLabel.Weight(weight: $0) }
            default: return nil
            }
        }
        
        let content = String(data: try! Data(contentsOf: URL(fileURLWithPath: fileName)), encoding: String.Encoding.utf8)!
        let lines = content.components(separatedBy: CharacterSet.newlines)
        let description = lines[0]
        let exerciseType = MKExerciseType(exerciseId: lines[1])!
        let rows: [MRLoadedSession.Row] = lines[2..<lines.count].flatMap { line in
            let lineComponents = line.componentsSeparatedByString(",")
            if let exerciseId = lineComponents.first,
                let detail = detail(exerciseId) {
                let labels = lineComponents[1..<lineComponents.count].flatMap(parseLabel)
                return (detail, labels)
            }
            return nil
        }
        return MRLoadedSession(description: description, rows: rows, exerciseType: exerciseType)
    }


}
