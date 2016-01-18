import UIKit
import MuvrKit
import Charts

/// Adds support for "previous" steps; the usage is on tap of the back button 
/// in the controller below.
extension MRAggregate {
    
    /// Indicates whether there is a previous step to go to
    var hasPrevious: Bool {
        switch self {
        case .Types: return false
        default: return true
        }
    }
    
    /// Indicates whether it is possible to start a session for this aggregate
    var isStartable: Bool {
        switch self {
        case .Types: return false
        default: return true
        }
    }
    
    /// Goes to the previous i.e. more general state
    var previous: MRAggregate {
        switch self {
        case .Types: return .Types
        case .MuscleGroups(_): return .Types
        case .Exercises(_): return .MuscleGroups(inType: .ResistanceTargeted)
        }
    }
    
}

///
/// Displays the basic stats for this user
///
class MRStatisticsViewController : UIViewController, ChartViewDelegate {
    
    @IBOutlet weak var pieChartView: PieChartView!
    @IBOutlet weak var pieChartBackButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    
    /// The averages computed for the given ``aggregate``. Keep these two in sync!
    private var averages: [(MRAggregateKey, MRAverage)] = []
    /// The aggregate to compute the ``averages`` for. Keep these two in sync!
    private var aggregate: MRAggregate = .Types
    
    /// A transform function to pull values out from an MRAverage instance
    private var transform: MRAverage -> Double = { Double($0.count) }

    // On load, we set up the views and hide the back button by default
    // We also set up the < symbol for the back button
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
        
        if let image = UIImage(named: "UIButtonBarArrowLeft") {
            image.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
            pieChartBackButton.setImage(image, forState: UIControlState.Normal)
        }
        
        startButton.hidden = true
    }
    
    // On appearance, show all .Types
    override func viewDidAppear(animated: Bool) {
        reloadAverages(.Types)
    }
    
    // Goes one step back
    @IBAction func back() {
        reloadAverages(aggregate.previous)
    }
    
    // Starts the selected session
    @IBAction func start() {
        switch aggregate {
        case .MuscleGroups(let type):
            try! MRAppDelegate.sharedDelegate().startSession(forExerciseType: type.concrete, start: NSDate(), id: NSUUID().UUIDString, sync: true)
        case .Exercises(let muscleGroup):
            try! MRAppDelegate.sharedDelegate().startSession(forExerciseType: .ResistanceTargeted(muscleGroups: [muscleGroup]), start: NSDate(), id: NSUUID().UUIDString, sync: true)
        default: break
        }
    }
    
    // The user has tapped on the toolbar, wanting to see a different field from the averages
    @IBAction func transformSelected(sender: UISegmentedControl) {
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
    
    // The user has selected one of the pies on the chart. Drill down to it, if possible.
    func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: ChartHighlight) {
        let (key, _) = averages[entry.xIndex]
        switch key {
        case .ExerciseType(let exerciseType): reloadAverages(.MuscleGroups(inType: exerciseType))
        case .MuscleGroup(let muscleGroup): reloadAverages(.Exercises(inMuscleGroup: muscleGroup))
        case .NoMuscleGroup: reloadAverages(.MuscleGroups(inType: .ResistanceWholeBody))
        case .Exercise(_): break
        }
    }

    ///
    /// Updates the ``aggregate`` and ``averages`` states according to the parameter, and
    /// displays the latest on the chart.
    /// - parameter aggregate: the new aggregate
    ///
    private func reloadAverages(aggregate: MRAggregate) {
        self.aggregate = aggregate
        // Without this, the ``setTitle:forState:`` animation appears awkwardly 
        UIView.performWithoutAnimation {
            self.pieChartBackButton.setTitle(aggregate.title, forState: UIControlState.Normal)
            self.pieChartBackButton.layoutIfNeeded()
            if aggregate.isStartable {
                self.startButton.setTitle("Start %@ session".localized(aggregate.title), forState: UIControlState.Normal)
            }
        }
        pieChartBackButton.hidden = !aggregate.hasPrevious
        startButton.hidden = !aggregate.isStartable
        averages = []
        //MRManagedClassifiedExercise.averages(inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext, aggregate: aggregate)
        reloadAveragesChart()
    }
    
    ///
    /// Reloads the chart view from the ``self.averages`` state. Viz ``transformSelected:``.
    ///
    private func reloadAveragesChart() {
        var ys: [BarChartDataEntry] = []
        var xs: [String] = []
        for (index, (key, average)) in averages.enumerate() {
            ys.append(BarChartDataEntry(value: transform(average), xIndex: index, data: nil))
            xs.append(key.title)
        }
        let dataSet = PieChartDataSet(yVals: ys)
        dataSet.colors = ChartColorTemplates.colorful() + ChartColorTemplates.joyful()
        if ys.count > 1 { dataSet.sliceSpace = 2 }
        
        pieChartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0, easingOption: ChartEasingOption.EaseOutCirc)
        pieChartView.data = PieChartData(xVals: xs, dataSet: dataSet)
        pieChartView.highlightValues([])
    }
    
}
