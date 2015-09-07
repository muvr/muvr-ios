import Foundation
import XCTest

class MRDataModelTests: XCTestCase {
    
    private func randomString(len: Int) -> String {
        let charSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var c = Array(charSet)
        var s: String = ""
        for n in (1...len) {
            s.append(c[Int(arc4random()) % c.count])
        }
        return s
    }

    private func example() -> MRResistanceExerciseExample {
        return MRResistanceExerciseExample(classified: [], correct: MRClassifiedResistanceExercise(MRResistanceExercise(id: randomString(20))))
    }
    
    private func exampleData() -> NSData {
        return randomString(100).dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: false)!
    }

    private func insertSession(on date: NSDate, exampleCount: Int) -> (NSUUID, MRResistanceExerciseSession, [(MRResistanceExerciseExample, NSData)]) {
        let id = NSUUID()
        let model = MRExerciseModel(id: randomString(10), title: randomString(20), exercises: [])
        let session = MRResistanceExerciseSession(startDate: NSDate(), intendedIntensity: 1, exerciseModel: model, title: randomString(20))
        
        let eds = (0..<exampleCount).map { x in return (self.example(), self.exampleData()) }
        
        MRDataModel.MRResistanceExerciseSessionDataModel.insert(id, session: session)
        eds.forEach { ed in
            let (e, d) = ed
            MRDataModel.MRResistanceExerciseSessionDataModel.insertResistanceExerciseExample(NSUUID(), sessionId: id, example: e, fusedSensorData: d)
        }

        return (id, session, eds)
    }
    
    func testSessionMerging() {
        let midnight = NSDate().dateOnly
        MRDataModel.MRResistanceExerciseSessionDataModel.deleteAll()
        let s1 = insertSession(on: midnight.addDays(0), exampleCount: 10)
        let s2 = insertSession(on: midnight.addDays(0), exampleCount: 20)
        
        let res = MRDataModel.MRResistanceExerciseSessionDataModel.find(on: s1.1.startDate)
        println(res)
    }
    
}