import Foundation

class MRExerciseSessionProgressViewController : UIViewController, UITableViewDelegate, UITableViewDataSource,
    MRExerciseBlockDelegate, MRExercisingApplicationStateDelegate, MRClassificationPipelineDelegate, MRTrainingPipelineDelegate, MRDeviceDataDelegate {
    static let storyboardId: String = "MRExerciseSessionProgressViewController"
    private var resistanceExercises: [MRClassifiedResistanceExercise] = {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
        return (0..<10).map { id in return MRClassifiedResistanceExercise(MRResistanceExercise(id: "Test \(id)")) }
        #else
        return []
        #endif
    }()

    @IBOutlet var tableView: UITableView!
    private let sessionProgressView: MRResistanceExerciseSessionProgressView
    private let exerciseProgressView: MRResistanceExerciseProgressView
    
    private var started: Bool = false
    private var timer: NSTimer?
    private var startTime: NSDate?
    private var collectedData: [[Double]] = [[], [], []]
    
    required init(coder aDecoder: NSCoder) {
        sessionProgressView = MRResistanceExerciseSessionProgressView(coder: aDecoder)
        exerciseProgressView = MRResistanceExerciseProgressView(coder: aDecoder)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        exerciseProgressView.setTime(0, max: 60)
        exerciseProgressView.setRepetitions(0, max: 20)
    }
    
    private func start() {
        if started { return }
        
        exerciseProgressView.setTime(0, max: 60)
        exerciseProgressView.setRepetitions(0, max: 20)
        exerciseProgressView.setText("")

        started = true
        collectedData = [[], [], []]
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "update", userInfo: nil, repeats: true)
        startTime = NSDate()
        tableView.reloadData()
    }
    
    private func stop() {
        if !started { return }
        
        started = false
        timer?.invalidate()
        tableView.reloadData()
        timer = nil
    }
    
    func update() -> Void {
        if let elapsed = startTime?.timeIntervalSinceDate(NSDate()) {
            let time = Int(-elapsed) % 60
            #if (arch(i386) || arch(x86_64)) && os(iOS)
                if time > 10 { stop() }
            #endif

            exerciseProgressView.setTime(time, max: 60)
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

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if started {
            return tableView.frame.width
        }
        return 212
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if started {
            return exerciseProgressView
        } else {
            return sessionProgressView
        }
    }
    
    func deviceDataDecoded3D(rows: [AnyObject]!, fromSensor sensor: UInt8, device deviceId: UInt8, andLocation location: UInt8) {
        let threed = rows as! [Threed]
        for e in threed {
            collectedData[0].append(Double(e.x))
            collectedData[1].append(Double(e.y))
            collectedData[2].append(Double(e.z))
        }
        
        let estimator = MRRepetitionsEstimator()
        let repetitions = estimator.numberOfRepetitions(collectedData) ?? 0
        if(exerciseProgressView.repetitions.value < CGFloat(repetitions)){
            exerciseProgressView.setRepetitions(repetitions, max: 20)
        }
    }
    
    func deviceDataDecoded1D(rows: [AnyObject]!, fromSensor sensor: UInt8, device deviceId: UInt8, andLocation location: UInt8) {
        // TODO: not implemented
    }
    
    func exerciseEnded() {
        stop()
    }
    
    func exercising() {
        start()
    }
    
    func moving() {
        start()
    }
    
    func notMoving() {
        stop()
    }
    
    func exerciseLogged(examples: [MRResistanceExerciseExample]) {
        resistanceExercises = examples.flatMap { $0.correct }
        sessionProgressView.setResistenceExercises(resistanceExercises)
        stop()
        tableView.reloadData()
    }
    
    func classificationCompleted(result: [AnyObject]!, fromData data: NSData!) {
        exerciseProgressView.setText("Classified")
    }
    
    func classificationEstimated(result: [AnyObject]!) {
        exerciseProgressView.setText("Estimated")
    }
    
    func trainingCompleted(exercise: MRResistanceExercise!, fromData data: NSData!) {
        exerciseProgressView.setText("Trained")
    }
    
}
