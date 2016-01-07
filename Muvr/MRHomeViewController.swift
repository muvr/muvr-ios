import UIKit
import Charts

class MRHomeViewController : UIViewController, ChartViewDelegate {

    @IBOutlet weak var pieChartView: PieChartView!
    @IBOutlet weak var pieChartBackButton: UIButton!

    private var averages: [MRManagedClassifiedExercise.Average] = []

    private var exerciseIdPrefix: String?
    private var transform: MRManagedClassifiedExercise.Average -> Double = { Double($0.count) }

    override func viewDidLoad() {
        pieChartBackButton.hidden = true
        
        pieChartView.delegate = self
        pieChartView.usePercentValuesEnabled = true
        pieChartView.holeTransparent = true
        pieChartView.holeRadiusPercent = 0.58
        pieChartView.transparentCircleRadiusPercent = 0.61
        pieChartView.descriptionText = ""

        pieChartView.drawHoleEnabled = true
        pieChartView.rotationAngle = 0.0
        pieChartView.rotationEnabled = false
        pieChartView.highlightPerTapEnabled = true
        
        pieChartView.usePercentValuesEnabled = false
        
        pieChartView.legend.enabled = false
    }
    
    override func viewDidAppear(animated: Bool) {
        averages = MRManagedClassifiedExercise.averages(inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext, exerciseIdPrefix: exerciseIdPrefix)
        reloadAveragesChart()
    }
    
    private func reloadAveragesChart() {
        var ys: [BarChartDataEntry] = []
        var xs: [String] = []
        for (index, average) in averages.enumerate() {
            ys.append(BarChartDataEntry(value: transform(average), xIndex: index, data: average.exerciseId))
            xs.append(NSLocalizedString(average.exerciseId, comment: "\(average.exerciseId) exercise").localizedCapitalizedString)
        }
        let dataSet = PieChartDataSet(yVals: ys)
        dataSet.colors = ChartColorTemplates.colorful() + ChartColorTemplates.joyful()
        if ys.count > 1 { dataSet.sliceSpace = 2 }
        
        pieChartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0, easingOption: ChartEasingOption.EaseOutCirc)
        pieChartView.data = PieChartData(xVals: xs, dataSet: dataSet)
        pieChartView.highlightValues([])
    }
    
    @IBAction
    func resetExerciseIdPrefix() {
        exerciseIdPrefix = nil
        averages = MRManagedClassifiedExercise.averages(inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext, exerciseIdPrefix: exerciseIdPrefix)
        pieChartBackButton.hidden = true
        reloadAveragesChart()
    }
    
    @IBAction
    func transformSelected(sender: UISegmentedControl) {
        // # W R I D
        switch sender.selectedSegmentIndex {
        case 0: /* # */ transform = { Double($0.count) }
        case 1: /* W */ transform = { $0.averageWeight }
        case 2: /* R */ transform = { Double($0.averageRepetitions) }
        case 3: /* I */ transform = { $0.averageIntensity }
        case 4: /* D */ transform = { $0.averageDuration }
        default: fatalError("Match error")
        }
        reloadAveragesChart()
    }
    
    func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: ChartHighlight) {
        if let exerciseId = entry.data as? String where exerciseIdPrefix == nil {
            exerciseIdPrefix = exerciseId + "/"
            pieChartBackButton.hidden = false
            averages = MRManagedClassifiedExercise.averages(inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext, exerciseIdPrefix: exerciseIdPrefix)
            reloadAveragesChart()
        }
    }
    
}
