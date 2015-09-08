import Foundation

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
    @IBOutlet var progressView: MRResistanceExerciseProgressView!
 
    private var timer: NSTimer?
    private var startTime: NSDate?
    
    override func viewDidLoad() {
        progressView.setTime(0, max: 60)
        progressView.setRepetitions(0, max: 20)
    }
    
    private func start() {
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "update", userInfo: nil, repeats: true)
            startTime = NSDate()
        }
    }
    
    private func stop() {
        timer?.invalidate()
        progressView.setTime(0, max: 60)
        progressView.setRepetitions(0, max: 20)
        progressView.exercisingImageHidden = true
        progressView.setText("")
        timer = nil
    }
    
    func update() -> Void {
        if let elapsed = startTime?.timeIntervalSinceDate(NSDate()) {
            let time = Int(-elapsed) % 60
            progressView.setTime(time, max: 60)
            progressView.setRepetitions(time / 3, max: 20)
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
        progressView.exercisingImageHidden = true
        stop()
    }
    
    func exercising() {
        progressView.exercisingImageHidden = false
        start()
    }
    
    func moving() {
        progressView.exercisingImageHidden = false
        start()
    }
    
    func notMoving() {
        progressView.exercisingImageHidden = true
    }
    
    func exerciseLogged(examples: [MRResistanceExerciseExample]) {
        resistanceExercises = examples.flatMap { $0.correct }
        stop()
        tableView.reloadData()
    }
    
    func classificationCompleted(result: [AnyObject]!, fromData data: NSData!) {
        progressView.setText("Classified")
        progressView.exercisingImageHidden = true
    }
    
    func classificationEstimated(result: [AnyObject]!) {
        progressView.setText("Estimated")
        progressView.exercisingImageHidden = true
    }
    
    func trainingCompleted(exercise: MRResistanceExercise!, fromData data: NSData!) {
        progressView.setText("Trained")
        progressView.exercisingImageHidden = true
    }
    
}
