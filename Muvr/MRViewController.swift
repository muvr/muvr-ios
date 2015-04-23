import UIKit
import Charts

class MRViewController: UIViewController, MRExerciseBlockDelegate, MRDeviceDataDelegate, MRClassificationPipelineDelegate, MRDeviceSessionDelegate {
    private let preclassification: MRPreclassification = MRPreclassification()
    private let pcd = MRRawPebbleConnectedDevice()
    private var data: [[NSNumber]] = []
    
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var lineChartView: FixedLineChartView!
    

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
        
        func mkLineChartDataSet(values: [[NSNumber]], index: Int, label: String, color: UIColor) -> LineChartDataSet {
            var cdes: [ChartDataEntry] = []
            for (index, val) in enumerate(values) {
                cdes += [ChartDataEntry(value: val[index] as Float, xIndex: index)]
            }
            let ds = LineChartDataSet(yVals: cdes, label: label)
            ds.circleRadius = 0
            ds.colors = [color]
            return ds
        }
        
        self.data += rows as! [[NSNumber]]
        
        if (self.data.count > 1000) {
            self.data = Array(self.data[rows.count..<self.data.count])
        }
        
        var xVals: [String] = []
        for i in 0..<self.data.count {
            xVals += [String(i)]
        }
        
        lineChartView.setScaleMinima(1, scaleY: 1)
        lineChartView.leftAxis.startAtZeroEnabled = false
        lineChartView.rightAxis.startAtZeroEnabled = false
        lineChartView.setVisibleXRange(CGFloat(100))
        lineChartView.setVisibleYRange(3000, axis: ChartYAxis.AxisDependency.Left)
        lineChartView.setVisibleYRange(3000, axis: ChartYAxis.AxisDependency.Right)
        
        let data = LineChartData(xVals: xVals, dataSets: [
            mkLineChartDataSet(self.data, 0, "X", UIColor.redColor()),
            mkLineChartDataSet(self.data, 1, "Y", UIColor.greenColor()),
            mkLineChartDataSet(self.data, 2, "Z", UIColor.blueColor()),
        ])
        lineChartView.data = data;
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
