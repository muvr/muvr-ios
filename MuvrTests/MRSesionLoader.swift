import Foundation
import MuvrKit
@testable import Muvr

struct MRLoadedSession {
    typealias Row = (MKExerciseDetail, [MKExerciseLabel])
    
    let description: String
    let rows: [Row]
    let exerciseType: MKExerciseType
}

class MRSesionLoader {
    private init() {
        
    }
    
    static func read(fileName: String, properties: MKExercise.Id -> [MKExerciseProperty]) -> MRLoadedSession {
        
        func parseLabel(text: String) -> MKExerciseLabel? {
            let components = text.componentsSeparatedByString("=")
            if components.count != 2 { return nil }
            switch (components.first!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()), components.last!) {
            case ("R", let text): return Int(text).map { MKExerciseLabel.Repetitions(repetitions: $0) }
            case ("I", let text): return Double(text).map { MKExerciseLabel.Intensity(intensity: $0) }
            case ("W", let text): return Double(text).map { MKExerciseLabel.Weight(weight: $0) }
            default: return nil
            }
        }
        
        let content = String(data: NSData(contentsOfFile: fileName)!, encoding: NSUTF8StringEncoding)!
        let lines = content.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        let description = lines[0]
        let exerciseType = MKExerciseType(exerciseId: lines[1])!
        let rows: [MRLoadedSession.Row] = lines[2..<lines.count].flatMap { line in
            let lineComponents = line.componentsSeparatedByString(",")
            if let exerciseId = lineComponents.first,
                let exerciseType = MKExerciseType(exerciseId: exerciseId) {
                let labels = lineComponents[1..<lineComponents.count].flatMap(parseLabel)
                return ((exerciseId, exerciseType, properties(exerciseId)), labels)
            }
            return nil
        }
        return MRLoadedSession(description: description, rows: rows, exerciseType: exerciseType)
    }


}