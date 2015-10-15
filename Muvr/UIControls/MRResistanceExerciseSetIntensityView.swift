import Foundation
import Charts
import MuvrKit

class MRResistanceExerciseIntensityView : BarChartView {
    
    private class func colorFor(intensity intensity: MKExerciseIntensity) -> UIColor {
        if intensity <= 0.3 {
            // very light -> #59ABE3
            // was return UIColor.grayColor()
            return UIColor(red: 0.349, green: 0.671, blue: 0.89, alpha: 1)
        } else if intensity <= 0.45 {
            // light -> 3498DB (was #5595E6)
            // was return UIColor(red: 0.333, green: 0.584, blue: 0.902, alpha: 1)
            return UIColor(red: 0.204, green: 0.596, blue: 0.859, alpha: 1)
        } else if intensity <= 0.65 {
            // moderate -> 4183D7 (was #3DA24D)
            // was return UIColor(red: 0.239, green: 0.635, blue: 0.302, alpha: 1)
            return UIColor(red: 0.255, green: 0.514, blue: 0.843, alpha: 1)
        } else if intensity <= 0.75 {
            // hard -> 446CB3 (was #E9B000)
            // was return UIColor(red: 0.914, green: 0.69, blue: 0, alpha: 1)
            return UIColor(red: 0.267, green: 0.424, blue: 0.702, alpha: 1)
        } else if intensity <= 0.87 {
            // very hard -> 1F3A93 (was #CE313E)
            // was return UIColor(red: 0.808, green: 0.192, blue: 0.243, alpha: 1)
            return UIColor(red: 0.122, green: 0.227, blue: 0.576, alpha: 1)
        }
        // bleeding eyes -> 22313F (was #942193)
        // was return UIColor(red: 0.58, green: 0.129, blue: 0.576, alpha: 1)
        return UIColor(red: 0.133, green: 0.192, blue: 0.247, alpha: 1)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        legend.enabled = false
        leftAxis.enabled = false
        rightAxis.enabled = false
        xAxis.enabled = false
        gridBackgroundColor = UIColor.clearColor()
        userInteractionEnabled = false
        descriptionText = ""
    }

    func setResistenceExercises(exercises: [MKClassifiedExercise]) -> Void {

        let repetitions = exercises.enumerate().map { (i: Int, exercise: MKClassifiedExercise) -> (ChartDataEntry, UIColor) in
            switch exercise {
            case .Resistance(confidence: _, exerciseId: _, duration: _, let repetitions, let intensity, weight: _):
                let color = MRResistanceExerciseIntensityView.colorFor(intensity: intensity ?? 0.5)
                let repetitions = repetitions ?? 10
                return (BarChartDataEntry(value: Double(repetitions), xIndex: i), color)
            }
        }
        
        let xs = exercises.enumerate().map { (i, _) in return String(i + 1) }
        
        let repetitionsAndIntensities = BarChartDataSet(yVals: repetitions.map { $0.0 }, label: "")
        repetitionsAndIntensities.colors = repetitions.map { $0.1 }
        
        let bcd = BarChartData(xVals: xs, dataSet: repetitionsAndIntensities)
        bcd.setDrawValues(false)
        
        data = bcd
    }
    
}
