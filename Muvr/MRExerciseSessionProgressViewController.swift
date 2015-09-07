import Foundation
import MBCircularProgressBar

class MRExerciseSessionProgressViewController : UIViewController, UITableViewDelegate, UITableViewDataSource,
    MRExerciseBlockDelegate, MRExercisingApplicationStateDelegate, MRClassificationPipelineDelegate, MRTrainingPipelineDelegate {
    static let storyboardId: String = "MRExerciseSessionProgressViewController"
    private var resistanceExercises: [MRClassifiedResistanceExercise] = {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
        return (0..<10).map { id in return MRClassifiedResistanceExercise(MRResistanceExercise(id: "Test \(id)")) }
        #else
        return []
        #endif
    }()

    @IBOutlet var tableView: UITableView!
    @IBOutlet var label: UILabel!
    @IBOutlet var time: MBCircularProgressBarView!
    @IBOutlet var repetitions: MBCircularProgressBarView!
 
    private var timer: NSTimer?
    private var startTime: NSDate?
    
    override func viewDidLoad() {
        time.value = 0
        repetitions.value = 0
    }
    
    private func start() {
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "update", userInfo: nil, repeats: true)
            startTime = NSDate()
        }
    }
    
    private func stop() {
        timer?.invalidate()
        time.value = 0
        timer = nil
    }
    
    func update() -> Void {
        if let elapsed = startTime?.timeIntervalSinceDate(NSDate()) {
            time.value = CGFloat(Int(-elapsed) % 60)
            repetitions.value = CGFloat(Int(time.value) / 3)
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resistanceExercises.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let exercise = resistanceExercises[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("resistanceExercise") as! UITableViewCell
        cell.textLabel?.text = exercise.resistanceExercise.title
        cell.detailTextLabel?.text = "Detail"
        return cell
    }
    
    func exerciseEnded() {
        label.text = "Exercise ended"
        stop()
    }
    
    func exercising() {
        label.text = "Exercising"
        start()
    }
    
    func moving() {
        label.text = "Moving"
        start()
    }
    
    func notMoving() {
        label.text = "Not moving"
    }
    
    func exerciseLogged(examples: [MRResistanceExerciseExample]) {
        resistanceExercises = examples.flatMap { $0.correct }
        stop()
        tableView.reloadData()
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
