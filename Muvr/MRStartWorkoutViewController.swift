import UIKit
import MuvrKit

class MRStartWorkoutViewController: UIViewController, MRCircleViewDelegate  {
    @IBOutlet private weak var startButton: MRCircleWorkoutView!
    @IBOutlet private weak var scrollView: UIScrollView!
    private var upcomingSessions: [(MRSessionType, [MRAchievement])] = []
    private var selectedSession: MRSessionType? = nil
    
    override func viewDidLoad() {
        setTitleImage(named: "muvr_logo_white")
        scrollView.accessibilityIdentifier = "Workouts"
        startButton.delegate = self
        startButton.pickerHidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        let app = MRAppDelegate.sharedDelegate()
        upcomingSessions = app.sessionTypes.map { ($0, app.achievementsForSessionType($0)) }
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
        startButton.sessionType = selectedSession
    }

    
    private func displayWorkouts() {
        if let sessionType = upcomingSessions.first?.0 {
            displayMainWorkout(sessionType)
        }
        
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        
        let buttonWidth = scrollView.frame.width / 3
        scrollView.contentSize = CGSizeMake(buttonWidth * CGFloat(upcomingSessions.count), scrollView.frame.height)
        
        if upcomingSessions.count > 1 {
            for sessionType in upcomingSessions {
                let button = MRAlternativeWorkoutButton(type: UIButtonType.System)
                button.lineWidth = 2
                button.color = MRColor.gray
                button.sessionType = sessionType.0
                button.achievement = sessionType.1.first // display only 1st achievement
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
    
    private func displayMainWorkout(sessionType: MRSessionType) {
        selectedSession = sessionType
        startButton.sessionType = sessionType
        startButton.headerTitle = "Start".localized()
        
        let achievements = upcomingSessions.filter { $0.0.name == sessionType.name }.first?.1 ?? []
        let views: [UIView] = achievements.map { achievement in
            let image = UIImage(named: achievement)
            return UIImageView(image: image)
        }
        startButton.labelViews = views
    }
    
    @objc private func selectAnotherWorkout() {
        let backButton = UIBarButtonItem()
        backButton.title = ""
        navigationItem.backBarButtonItem = backButton
        performSegueWithIdentifier("manual", sender: nil)
    }
    
    @objc private func changeWorkout(sender: MRAlternativeWorkoutButton) {
        if let sessionType = sender.sessionType {
            displayMainWorkout(sessionType)
        }
    }
    
    /// MARK: MRCircleViewDelegate
    
    func circleViewTapped(circleView: MRCircleView) {
        if let sessionType = selectedSession {
            try! MRAppDelegate.sharedDelegate().startSession(sessionType)
        }
    }
    
}