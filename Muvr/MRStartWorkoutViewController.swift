import UIKit
import MuvrKit

class MRStartWorkoutViewController: UIViewController  {
    @IBOutlet weak var startButton: MRAlternativeWorkoutButton!
    @IBOutlet weak var scrollView: UIScrollView!
    private var upcomingSessions: [MRSessionType] = []
    private var selectedSession: MRSessionType? = nil
    
    override func viewDidLoad() {
        setTitleImage(named: "muvr_logo_white")
        scrollView.accessibilityIdentifier = "Workouts"
    }
    
    override func viewWillAppear(animated: Bool) {
        upcomingSessions = MRAppDelegate.sharedDelegate().sessionTypes
        displayWorkouts()
    }
    
    ///
    /// Compute the buttons' frames after scrollView layout
    ///
    override func viewDidLayoutSubviews() {
        let buttonWidth = scrollView.frame.width / 3
        let buttonPadding: CGFloat = 5
        scrollView.contentSize = CGSizeMake(buttonWidth * CGFloat(scrollView.subviews.count), scrollView.frame.height)
        for (index, button) in scrollView.subviews.enumerate() {
            button.frame = CGRectMake(CGFloat(index) * buttonWidth + (buttonPadding / 2), buttonPadding, buttonWidth - buttonPadding, buttonWidth - buttonPadding)
        }
    }

    
    private func displayWorkouts() {
        if let sessionType = upcomingSessions.first {
            selectedSession = sessionType
            startButton.setTitle("Start %@".localized(sessionType.name), forState: .Normal)
        }
        
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        
        let buttonWidth = scrollView.frame.width / 3
        scrollView.contentSize = CGSizeMake(buttonWidth * CGFloat(upcomingSessions.count), scrollView.frame.height)
        
        if upcomingSessions.count > 1 {
            for sessionType in upcomingSessions {
                let button = MRAlternativeWorkoutButton(type: UIButtonType.System)
                button.lineWidth = 2
                button.color = MRColor.gray
                button.sessionType = sessionType
                button.setTitleColor(MRColor.black, forState: .Normal)
                button.addTarget(self, action: #selector(MRStartWorkoutViewController.changeWorkout(_:)), forControlEvents: [.TouchUpInside])
                scrollView.addSubview(button)
            }
        }
        
        // add "Start another workout" button
        let button = MRAlternativeWorkoutButton(type: UIButtonType.System)
        button.color = MRColor.orange
        button.backgroundColor = MRColor.orange
        button.setTitleColor(.whiteColor(), forState: .Normal)
        button.setTitle("Start another workout".localized(), forState: .Normal)
        button.addTarget(self, action: #selector(MRStartWorkoutViewController.selectAnotherWorkout), forControlEvents: [.TouchUpInside])
        scrollView.addSubview(button)
        
    }
    
    @objc private func selectAnotherWorkout() {
        let backButton = UIBarButtonItem()
        backButton.title = ""
        navigationItem.backBarButtonItem = backButton
        performSegueWithIdentifier("manual", sender: nil)
    }
    
    @objc private func changeWorkout(sender: MRAlternativeWorkoutButton) {
        if let sessionType = sender.sessionType {
            selectedSession = sessionType
            startButton.setTitle("Start %@".localized(sessionType.name), forState: .Normal)
        }
    }
    
    @IBAction private func startWorkout(sender: MRAlternativeWorkoutButton) {
        if let sessionType = selectedSession {
            try! MRAppDelegate.sharedDelegate().startSession(sessionType)
        }
    }
    
}