import Foundation

class MRExerciseSessionViewController : UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    private var timer: NSTimer?
    private var pageControl: UIPageControl!
    
    override func viewWillDisappear(animated: Bool) {
        if let x = timer { x.invalidate() }
        navigationItem.prompt = nil
        pageControl.removeFromSuperview()
        pageControl = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        
        let pagesStoryboard = UIStoryboard(name: "LiveSession", bundle: nil)
        pageViewControllers = ["classification", "devices", "sensorDataGroup"].map { pagesStoryboard.instantiateViewControllerWithIdentifier($0) as UIViewController }
        setViewControllers([pageViewControllers.first!], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
        
        if let nc = navigationController {
            let navBarSize = nc.navigationBar.bounds.size
            let origin = CGPoint(x: navBarSize.width / 2, y: navBarSize.height / 2 + navBarSize.height / 4)
            pageControl = UIPageControl(frame: CGRect(x: origin.x, y: origin.y, width: 0, height: 0))
            pageControl.numberOfPages = 3
            nc.navigationBar.addSubview(pageControl)
        }
        
        multiDeviceSessionEncoding(multi)
        
        // propagate to children
        if let session = exerciseSession {
            pageViewControllers.foreach { e in
                if let s = e as? ExerciseSessionSettable {
                    s.setExerciseSession(session)
                }
            }
        }
        
        startTime = NSDate()
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "tick", userInfo: nil, repeats: true)
    }
    
}