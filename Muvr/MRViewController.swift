import UIKit
import Charts

class MRViewController: UIViewController, MRExerciseBlockDelegate, MRDeviceDataDelegate, MRClassificationPipelineDelegate, MRDeviceSessionDelegate {
    private let preclassification: MRPreclassification = MRPreclassification()
    private let pcd = MRRawPebbleConnectedDevice()
    private var data: [Threed] = []
    
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
        //NSLog("%@", data)
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
        
        func mkLineChartDataSet<A>(values: [A], label: String, color: UIColor, f: A -> Float) -> LineChartDataSet {
            let cdes: [ChartDataEntry] = values.zipWithIndex().map { (index, a) in
                return ChartDataEntry(value: f(a) as Float, xIndex: index)
            }
            let ds = LineChartDataSet(yVals: cdes, label: label)
            ds.circleRadius = 0
            ds.colors = [color]
            return ds
        }
        
        self.data += rows as! [Threed]
        
        if (self.data.count > 1000) {
            self.data = Array(self.data[rows.count..<self.data.count])
        }
        
        var xVals: [String] = []
        for i in 0..<self.data.count {
            xVals += [String(i)]
        }
        
        lineChartView.setScaleEnabled(false)
        lineChartView.leftAxis.startAtZeroEnabled = false
        lineChartView.rightAxis.startAtZeroEnabled = false
        lineChartView.rightAxis.customAxisMax = 1500
        lineChartView.rightAxis.customAxisMin = -1500
        lineChartView.leftAxis.customAxisMax = 1500
        lineChartView.leftAxis.customAxisMin = -1500
        lineChartView.setVisibleXRange(100)
        lineChartView.setVisibleXRange(CGFloat(100))
        
        let xs = mkLineChartDataSet(self.data, "X", UIColor.redColor(), { (x: Threed) in return Float(x.x) })
        let ys = mkLineChartDataSet(self.data, "Y", UIColor.greenColor(), { (x: Threed) in return Float(x.y) })
        let zs = mkLineChartDataSet(self.data, "Z", UIColor.blueColor(), { (x: Threed) in return Float(x.z) })
        
        let data = LineChartData(xVals: xVals, dataSets: [xs, ys, zs])
        lineChartView.data = data
        if self.data.count > 100 {
            lineChartView.moveViewToX(self.data.count - 100)
        }
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
