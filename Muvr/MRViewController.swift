import UIKit
import Charts

class MRViewController: UIViewController, MRExerciseBlockDelegate, MRDeviceDataDelegate, MRClassificationPipelineDelegate, MRDeviceSessionDelegate {
    private let preclassification: MRPreclassification = MRPreclassification()
    private let pcd = MRRawPebbleConnectedDevice()
    
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var lineChartView: LineChartView!

    override func viewDidLoad() {
        preclassification.exerciseBlockDelegate = self
        preclassification.deviceDataDelegate = self
        preclassification.classificationPipelineDelegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        statusLabel.text = "---";
    }
    
    @IBAction
    func start() {
        statusLabel.text = "Starting...";
        pcd.start(self)
    }
    
    @IBAction
    func stop() {
        pcd.stop()
        statusLabel.text = "---";
    }
    
    @IBAction
    func send() {
        exerciseSessionPayload()
    }
    
    // TODO: Send correct fused / preprocessed sensor data
    func exerciseSessionPayload() {
        MRMuvrServer.sharedInstance.exerciseSessionPayload(MRExerciseSessionPayload(data: "payloadz")) {
            $0.cata(
                { e in println("Server request failed: " + e.localizedDescription) },
                r: { s in println("Server request success: " + s) })
        }
    }
    
    // MARK: MRDeviceSessionDelegate implementation
    func deviceSession(session: DeviceSession, endedFrom deviceId: DeviceId) {
        //
    }
    
    func deviceSession(session: DeviceSession, sensorDataNotReceivedFrom deviceId: DeviceId) {
        //
    }
    
    func deviceSession(session: DeviceSession, sensorDataReceivedFrom deviceId: DeviceId, atDeviceTime time: CFAbsoluteTime, data: NSData) {
        preclassification.pushBack(data, from: 0, at: time)
    }
    
    // MARK: MRExerciseBlockDelegate implementation
    
    func exerciseEnded() {
        statusLabel.text = "Exercise ended";
    }
    
    func exercising() {
        statusLabel.text = "Exercising";
    }
    
    func moving() {
        statusLabel.text = "Moving";
    }
    
    func notMoving() {
        statusLabel.text = "Not moving";
    }
    
    // MARK: MRDeviceDataDelegate
    func deviceDataDecoded(rows: [AnyObject]!) {
        let numberRows = rows as! [[NSNumber]]
        var xVals: [String] = []
        for i in 0..<numberRows[0].count {
            xVals += [String(i)]
        }
        
        lineChartView.setScaleEnabled(false)
        lineChartView.setVisibleXRange(CGFloat(xVals.count))
        lineChartView.setVisibleYRange(1500, axis: ChartYAxis.AxisDependency.Left)
        
        let dataSets = (rows as! [[NSNumber]]).map { (vals: [NSNumber]) -> LineChartDataSet in
            var cdes: [ChartDataEntry] = []
            for (index, val) in enumerate(vals) {
                cdes += [ChartDataEntry(value: val as Float, xIndex: index)]
            }
            let ds = LineChartDataSet(yVals: cdes)
            ds.circleRadius = 0
            ds.colors = [UIColor.redColor()]
            return ds
        }
        let data = LineChartData(xVals: xVals, dataSets: dataSets)
        lineChartView.data = data;
//        let xds = LineChartDataSet(
//        for row in rows as! [[NSNumber]] {
//            for v in row {
//                NSLog("%@", v)
//            }
//        }
    }
    
    // MARK: MRClassificationDelegate
    func classificationSucceeded() {//(exercise: String!, fromData data: NSData!) {
        println("Successfully classified exercise")
        // Positive sample: MuvrServer.sharedInstance...
    }
    
    func classificationAmbiguous() { //(exercises: [AnyObject]!, fromData data: NSData!) {
        println("Ambiguously classified exercise")
        // BT message to the watch -> decide
        // Positive sample: MuvrServer.sharedInstance...
    }
    
    func classificationFailed() { //(data: NSData!) {
        println("Failed to classify exercise")
        // Failning sample: MuvrServer.sharedInstance...
    }

}
