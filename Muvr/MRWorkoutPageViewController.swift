import UIKit

class MRWorkoutPageViewController: UIPageViewController {

    private enum SelectedControl: Int {
        case Library = 0
        case Custom = 1
    }
    
    private let segmentedControl = UISegmentedControl(items: ["Library".localized(), "Custom".localized()])
    private var customViewController: MRManualViewController!
    private var libraryViewController: MRLibraryViewController!
    
    override func viewDidLoad() {
        customViewController = storyboard?.instantiateViewControllerWithIdentifier("manual") as! MRManualViewController
        libraryViewController = storyboard?.instantiateViewControllerWithIdentifier("library") as! MRLibraryViewController
        
        setViewControllers([libraryViewController], direction: .Forward, animated: false, completion: nil)
        
        segmentedControl.addTarget(self, action: #selector(MRWorkoutPageViewController.changePage(_:)), forControlEvents: .ValueChanged)
        
        guard let frame = navigationController?.navigationBar.frame else { return }
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.clipsToBounds = true
        segmentedControl.frame = CGRectMake(frame.origin.x + 5, frame.origin.y + 2, frame.width - 7, frame.height - 8)
        segmentedControl.accessibilityIdentifier = "Workout control"
        navigationItem.titleView = segmentedControl
    }
    
    func changePage(sender: UISegmentedControl) {
        guard let selected = SelectedControl(rawValue: sender.selectedSegmentIndex) else { return }
        switch selected {
        case .Custom: setViewControllers([customViewController], direction: .Forward, animated: true, completion: nil)
        case .Library: setViewControllers([libraryViewController], direction: .Reverse, animated: true, completion: nil)
        }
    }
    
}
