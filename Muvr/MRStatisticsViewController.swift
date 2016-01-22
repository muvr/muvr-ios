import UIKit
import MuvrKit
import Charts
import CoreData

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
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    /// The averages computed for the given ``aggregate``. Keep these two in sync!
    private var averages: [(MRAggregateKey, MRAverage)] = []
    /// The aggregate to compute the ``averages`` for. Keep these two in sync!
    private var aggregate: MRAggregate = .Types
    
    /// A transform function to pull values out from an MRAverage instance
    private var transform: MRAverage -> Double = { Double($0.count) }
    
    // The number formatter used to display values on the pie chart
    private let formatter = NSNumberFormatter()
    
    // The label descriptors for the current aggregate
    private var labels: [MKExerciseLabelDescriptor] {
        return aggregate.labelsDescriptors.sort { $0.id < $1.id }
    }

    // On load, we set up the views and hide the back button by default
    // We also set up the < symbol for the back button
    override func viewDidLoad() {
        pieChartBackButton.hidden = true
        
        pieChartView.delegate = self
        pieChartView.holeTransparent = true
        pieChartView.holeRadiusPercent = 0.88
        pieChartView.transparentCircleRadiusPercent = 0.88
        pieChartView.descriptionText = ""
        
        pieChartView.drawHoleEnabled = true
        pieChartView.rotationAngle = 22
        pieChartView.rotationEnabled = false
        
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "persistedDataDidChanged:", name: NSManagedObjectContextDidSaveNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // Goes one step back
    @IBAction func back() {
        reloadAverages(aggregate.previous)
    }
    
    // Starts the selected session
    @IBAction func start() {
        switch aggregate {
        case .MuscleGroups(let type):
            try! MRAppDelegate.sharedDelegate().startSession(forExerciseType: type.concrete)
        case .Exercises(let muscleGroup):
            try! MRAppDelegate.sharedDelegate().startSession(forExerciseType: .ResistanceTargeted(muscleGroups: [muscleGroup]))
        default: break
        }
    }
    
    // The user has tapped on the toolbar, wanting to see a different field from the averages
    @IBAction func transformSelected(sender: UISegmentedControl) {
        formatter.maximumFractionDigits = 0
        formatter.numberStyle = .NoStyle
        // # W R I D
        switch sender.selectedSegmentIndex {
        case 0: /* # */ transform = { Double($0.count) }
        case 1: /* D */ transform = { $0.averageDuration }
        default:
            let label = labels[sender.selectedSegmentIndex - 2]
            transform = { $0.averages[label] ?? 0 }
            switch label {
            case .Weight:
                formatter.numberStyle = .DecimalStyle
                formatter.maximumFractionDigits = 2
            case .Intensity:
                formatter.numberStyle = .PercentStyle
            default: break
            }
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
                self.startButton.setTitle("Start %@ session".localized(aggregate.title).localizedCapitalizedString, forState: UIControlState.Normal)
            }
        }
        segmentedControl.removeAllSegments()
        segmentedControl.insertSegmentWithTitle("stats.count".localized().localizedCapitalizedString, atIndex: 0, animated: true)
        segmentedControl.insertSegmentWithTitle("stats.duration".localized().localizedCapitalizedString, atIndex: 1, animated: true)
        labels.forEach { label in
            let title = "stats.\(label.id)".localized().localizedCapitalizedString
            segmentedControl.insertSegmentWithTitle(title, atIndex: segmentedControl.numberOfSegments, animated: true)
        }
        segmentedControl.selectedSegmentIndex = 0
        transform = { Double($0.count) }
        
        pieChartBackButton.hidden = !aggregate.hasPrevious
        startButton.hidden = !aggregate.isStartable
        averages = MRManagedExerciseScalarLabel.averages(inManagedObjectContext: try! MRAppDelegate.superEvilMegacorpSharedDelegate().mainManagedObjectContext(), aggregate: aggregate)
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
        dataSet.colors = ChartColorTemplates.liberty() + ChartColorTemplates.pastel()
        if ys.count > 1 { dataSet.sliceSpace = 2 }
        
        pieChartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0, easingOption: ChartEasingOption.EaseOutCirc)
        pieChartView.data = PieChartData(xVals: xs, dataSet: dataSet)
        pieChartView.data?.setValueTextColor(UIColor.darkTextColor())
        pieChartView.data?.setValueFormatter(formatter)
        pieChartView.highlightValues([])
    }
    
    /// called when there is a change in persisted data
    internal func persistedDataDidChange(notif: NSNotification) {
        reloadAverages(self.aggregate)
    }
    
}
