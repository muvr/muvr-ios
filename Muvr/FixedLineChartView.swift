import Foundation
import Charts

public class FixedLineChartView : LineChartView {
    
    public override var chartYMax: Float {
       return 1500
    }
    
    public override var chartYMin: Float {
        return -1500
    }
}
