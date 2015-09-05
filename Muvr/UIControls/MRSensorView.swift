import Foundation
import Charts

///
/// Holds the key to the sensor view structure
///
struct MRSensorViewDataKey : Equatable, Hashable, Printable {
    var sensorId: UInt8
    var deviceId: UInt8

    var hashValue: Int {
        return sensorId.hashValue ^ deviceId.hashValue
    }
    
    var description: String {
        return String(format:"%2X:%2X", deviceId, sensorId)
    }
}

/// Implements Equatable for MRSensorDataViewKey
func ==(lhs: MRSensorViewDataKey, rhs: MRSensorViewDataKey) -> Bool {
    return lhs.deviceId == rhs.deviceId && lhs.sensorId == rhs.sensorId
}

///
/// A line chart view of the sensor data, grouped by device and sensor. It implements ``MRDeviceDataDelegate``,
/// allowing it to be used directly in the ``MRPreclassification`` instances.
///
class MRSensorView : LineChartView, MRDeviceDataDelegate {
    /// map of 3D values (acceleration, rotation, ...)
    private var threedData: [MRSensorViewDataKey : [Threed]] = [:]
    /// map of 1D values (heart rate, glucose levels, ...)
    private var onedData: [MRSensorViewDataKey : [NSNumber]] = [:]
    
    func deviceDataDecoded1D(rows: [AnyObject]!, fromSensor sensor: UInt8, device deviceId: UInt8, andLocation location: UInt8) {
        let rn = rows as! [NSNumber]
        let key = MRSensorViewDataKey(sensorId: sensor, deviceId: deviceId)
        self.onedData.updated(key, notFound: rn, update: { $0 + rn })
        self.onedData.updated(key, update: { self.trimTo(1000, values: $0) })
        refreshData(self.onedData, dataSets: onedLineChartDataSet)
    }
    
    func deviceDataDecoded3D(rows: [AnyObject]!, fromSensor sensor: UInt8, device deviceId: UInt8, andLocation location: UInt8) {
        let rt = rows as! [Threed]
        let key = MRSensorViewDataKey(sensorId: sensor, deviceId: deviceId)
        self.threedData.updated(key, notFound: rt, update: { $0 + rt })
        self.threedData.updated(key, update: { self.trimTo(1000, values: $0) })
        refreshData(self.threedData, dataSets: threedLineChartDataSet)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    /// set up basic parameters for the view
    private func initialize() {
        leftAxis.startAtZeroEnabled = false
        rightAxis.startAtZeroEnabled = false
        rightAxis.customAxisMax = 1500
        rightAxis.customAxisMin = -1500
        leftAxis.customAxisMax = 1500
        leftAxis.customAxisMin = -1500
    }
    
    // trim an array to at most ``count`` elements.
    private func trimTo<A>(count: Int, values: [A]) -> [A] {
        if values.count > count {
            return Array(values[100..<values.count])
        } else {
            return values
        }
    }

    /// create data sets from 1D data
    private func onedLineChartDataSet(label: String, values: [NSNumber]) -> [LineChartDataSet] {
        let vs = lineChartDataSetFrom(values, label: "\(label) - X", color: UIColor.redColor(), f: { (x: NSNumber) in return x.floatValue })
        
        return [vs]
    }
    
    /// create data sets from 3D data
    private func threedLineChartDataSet(label: String, values: [Threed]) -> [LineChartDataSet] {
        let xs = lineChartDataSetFrom(values, label: "\(label) - X", color: UIColor.redColor(), f: { (x: Threed) in return Float(x.x) })
        let ys = lineChartDataSetFrom(values, label: "\(label) - X", color: UIColor.greenColor(), f: { (x: Threed) in return Float(x.y) })
        let zs = lineChartDataSetFrom(values, label: "\(label) - X", color: UIColor.blueColor(), f: { (x: Threed) in return Float(x.z) })
    
        return [xs, ys, zs];
    }

    /// create a LineChartDataSet from an array of values, label, color and a function that extracts a value from element of A
    private func lineChartDataSetFrom<A>(values: [A], label: String, color: UIColor, f: A -> Float) -> LineChartDataSet {
        let cdes: [ChartDataEntry] = values.zipWithIndex().map { (index, a) in
            return ChartDataEntry(value: Double(f(a)), xIndex: index)
        }
        let ds = LineChartDataSet(yVals: cdes, label: label)
        ds.circleRadius = 0
        ds.colors = [color]
        return ds
    }

    /// display the data from the given values by constructing data sets by applying the ``dataSet`` function to every
    /// element in ``values``.
    private func refreshData<A>(values: [MRSensorViewDataKey : [A]], dataSets: (String, [A]) -> [LineChartDataSet]) {
        let viewSize = 100

        setVisibleXRange(minXRange: 0, maxXRange: CGFloat(viewSize))
        setScaleEnabled(false)

        var ds: [LineChartDataSet] = []
        var count: Int = 0
        for (k, v) in values {
            ds += dataSets(k.description, v)
            count = max(count, v.count)
        }
        
        var xVals: [String] = []
        for i in 0..<count {
            xVals += [String(i)]
        }

        self.data = LineChartData(xVals: xVals, dataSets: ds)
        if xVals.count > viewSize {
            moveViewToX(xVals.count - viewSize)
        }
    }
}
