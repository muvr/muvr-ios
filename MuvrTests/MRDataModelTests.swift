import Foundation
import XCTest

class MRDataModelTests: XCTestCase {

    
    func testExample() {
        let id = NSUUID()
        let model = MRExerciseModel(id: "test", title: "Test", exercises: [])
        let session = MRResistanceExerciseSession(startDate: NSDate(), intendedIntensity: 1, exerciseModel: model, title: "Test")
        
        func example() -> MRResistanceExerciseExample {
            //MRResistanceExerciseExample(classified: [], correct: MRCl)
            let correct = MRClassifiedResistanceExercise(MRResistanceExercise(id: "Test"))
            fatalError("Fixme")
        }
        
        func exampleData() -> NSData {
            fatalError("Fixme")
        }
        
        
        MRDataModel.MRResistanceExerciseSessionDataModel.insert(id, session: session)
        MRDataModel.MRResistanceExerciseSessionDataModel.insertResistanceExerciseExample(NSUUID(), sessionId: id, example: example(), fusedSensorData: exampleData())
        MRDataModel.MRResistanceExerciseSessionDataModel.find(on: NSDate())
    }
    
}