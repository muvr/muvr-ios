import UIKit

///
/// This page view controller uses a segmented control to navigate between
/// the library workout view controller and the custom workout view controller
///
class MRWorkoutPageViewController: UIPageViewController {

    private enum SelectedControl: Int {
        case Library = 0
        case Custom = 1
    }
    
    ///
    /// The segmented control in the navbar allowing to choose between a custom workout or one from the library
    ///
    private let segmentedControl = UISegmentedControl(items: ["Library".localized(), "Custom".localized()])
    
    ///
    /// The custom workout view controller
    ///
    private var customViewController: MRManualViewController!
    
    ///
    /// The library workout view controller
    ///
    private var libraryViewController: MRLibraryViewController!
    
    override func viewDidLoad() {
        // instanciates the view controllers
        customViewController = storyboard?.instantiateViewControllerWithIdentifier("manual") as! MRManualViewController
        libraryViewController = storyboard?.instantiateViewControllerWithIdentifier("library") as! MRLibraryViewController
        
        // display the "library" view controller by default
        setViewControllers([libraryViewController], direction: .Forward, animated: false, completion: nil)
        
        // register callback
        segmentedControl.addTarget(self, action: #selector(MRWorkoutPageViewController.changePage(_:)), forControlEvents: .ValueChanged)
        
        // setup segmented control
        guard let frame = navigationController?.navigationBar.frame else { return }
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.clipsToBounds = true
        segmentedControl.frame = CGRectMake(frame.origin.x + 5, frame.origin.y + 2, frame.width - 7, frame.height - 8)
        segmentedControl.accessibilityIdentifier = "Workout control"
        navigationItem.titleView = segmentedControl
    }
    
    ///
    /// Called when the selection of the segmented control changes.
    /// Dislays the view controller corresponding to the selected option (custom or library)
    ///
    func changePage(sender: UISegmentedControl) {
        guard let selected = SelectedControl(rawValue: sender.selectedSegmentIndex) else { return }
        switch selected {
        case .Custom: setViewControllers([customViewController], direction: .Forward, animated: true, completion: nil)
        case .Library: setViewControllers([libraryViewController], direction: .Reverse, animated: true, completion: nil)
        }
    }
    
}
