import Foundation

class MRExerciseSessionProgressViewController : UIViewController, UITableViewDelegate, UITableViewDataSource,
    MRExerciseBlockDelegate, MRExercisingApplicationStateDelegate, MRClassificationPipelineDelegate, MRTrainingPipelineDelegate {
    static let storyboardId: String = "MRExerciseSessionProgressViewController"

    @IBOutlet var tableView: UITableView!
    @IBOutlet var label: UILabel!
 
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        fatalError("Implement me")
    }
    
    func exerciseEnded() {
        label.text = "Exercise ended"
    }
    
    func exercising() {
        label.text = "Exercising"
    }
    
    func moving() {
        label.text = "Moving"
    }
    
    func notMoving() {
        label.text = "Not moving"
    }
    
    func exerciseLogged(examples: [MRResistanceExerciseExample]) {
        label.text = "Exercise logged \(examples)"
    }
    
    func classificationCompleted(result: [AnyObject]!, fromData data: NSData!) {
        label.text = "Classification completed \(result)"
    }
    
    func classificationEstimated(result: [AnyObject]!) {
        label.text = "Classification estimated \(result)"
    }
    
    func trainingCompleted(exercise: MRResistanceExercise!, fromData data: NSData!) {
        label.text = "Training completed \(exercise)"
    }
    
}
