import Foundation
import Charts

class MRResistanceExerciseSetIntensityView : BarChartView {
    
    private class func colorFor(#intensity: Float) -> UIColor {
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
        super.init(coder: aDecoder)
        legend.enabled = false
        leftAxis.enabled = false
        rightAxis.enabled = false
        xAxis.enabled = false
        gridBackgroundColor = UIColor.clearColor()
        userInteractionEnabled = false
        descriptionText = ""
    }

    func setResistenceExerciseSets(sets: [MRResistanceExerciseSet]) -> Void {
        func averageInSet(set: MRResistanceExerciseSet, f: MRResistanceExercise -> NSNumber?) -> Float? {
            let filtered = (set.sets as! [MRResistanceExercise]).flatMap { x in return f(x)?.floatValue }
            if filtered.count == 0 { return nil }
            return Float(filtered.count) / filtered.foldLeft(Float(0)) { (e, b) in return b + e }
        }

        func sumInSet(set: MRResistanceExerciseSet, f: MRResistanceExercise -> NSNumber?) -> Float? {
            let filtered = (set.sets as! [MRResistanceExercise]).flatMap { x in return f(x)?.floatValue }
            if filtered.count == 0 { return nil }
            return filtered.foldLeft(Float(0)) { (e, b) in return b + e }
        }

        let setsWithIndex = sets.zipWithIndex()
        let repetitions = setsWithIndex.map { (i, s) -> (ChartDataEntry, UIColor) in
            let color = MRResistanceExerciseSetIntensityView.colorFor(intensity: (averageInSet(s) { $0.intensity }) ?? 0.5)
            if let repetitions = (sumInSet(s) { $0.repetitions }) {
                return (BarChartDataEntry(value: repetitions, xIndex: i), color)
            }
            return (BarChartDataEntry(value: 10, xIndex: i), color)
        }
        
        let xs = setsWithIndex.map { (i, _) in return String(i + 1) }
        
        let repetitionsAndIntensities = BarChartDataSet(yVals: repetitions.map { $0.0 }, label: "")
        repetitionsAndIntensities.colors = repetitions.map { $0.1 }
        
        let bcd = BarChartData(xVals: xs, dataSet: repetitionsAndIntensities)
        bcd.setDrawValues(false)
        
        data = bcd
    }
    
}
