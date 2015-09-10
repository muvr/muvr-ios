import Foundation
import XCTest

class MRDataModelTests: XCTestCase {
    
    /// Generates random string of the given ``length``
    private func randomString(length: Int) -> String {
        let charSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var c = Array(charSet.characters)
        var s: String = ""
        for n in (1...length) {
            let randomIndex = Int(arc4random_uniform(UInt32(c.count)))
            s.append(c[randomIndex])
        }
        return s
    }

    /// Generates random MRResistanceExerciseExample
    private func example() -> MRResistanceExerciseExample {
        return MRResistanceExerciseExample(classified: [], correct: MRClassifiedResistanceExercise(MRResistanceExercise(id: randomString(20))))
    }

    /// Generates random NSData that could be used for ``fusedSensorData`` for the MRResistanceExerciseExample``
    private func exampleData() -> NSData {
        return randomString(100).dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: false)!
    }

    ///
    /// Generates & inserts a random MRResistanceExerciseSession on the given ``date`` with the given ``exampleCount`` examples.
    /// @return the generated session id, session, and array of (example, data)
    ///
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
        let (id1, session1, examples1) = insertSession(on: midnight.addDays(0), exampleCount: 1)
        let (id2, session2, examples2) = insertSession(on: midnight.addDays(0), exampleCount: 2)
        
        let res = MRDataModel.MRResistanceExerciseSessionDataModel.find(on: session1.startDate)
        XCTAssertEqual([id1, id2], res.map { $0.id })
    }
    
}