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
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
        scrollView.contentSize = CGSize(width: buttonWidth * CGFloat(scrollView.subviews.count), height: scrollView.frame.height)
        for (index, button) in scrollView.subviews.enumerated() {
            button.frame = CGRect(x: CGFloat(index) * buttonWidth + (buttonPadding / 2), y: buttonPadding, width: buttonWidth - buttonPadding, height: buttonWidth - buttonPadding)
        }
        startButton.sessionType = selectedSession
    }

    
    private func displayWorkouts() {
        if let sessionType = upcomingSessions.first?.0 {
            displayMainWorkout(sessionType)
        }
        
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        
        let buttonWidth = scrollView.frame.width / 3
        scrollView.contentSize = CGSize(width: buttonWidth * CGFloat(upcomingSessions.count), height: scrollView.frame.height)
        
        if upcomingSessions.count > 1 {
            for sessionType in upcomingSessions {
                let button = MRAlternativeWorkoutButton(type: UIButtonType.system)
                button.lineWidth = 2
                button.color = MRColor.gray
                button.sessionType = sessionType.0
                button.achievement = sessionType.1.first // display only 1st achievement
                button.setTitleColor(MRColor.black, for: UIControlState())
                button.addTarget(self, action: #selector(MRStartWorkoutViewController.changeWorkout(_:)), for: [.touchUpInside])
                scrollView.addSubview(button)
            }
        }
        
        // add "Start another workout" button
        let button = MRAlternativeWorkoutButton(type: UIButtonType.system)
        button.color = MRColor.orange
        button.backgroundColor = MRColor.orange
        button.setTitleColor(.white(), for: UIControlState())
        button.setTitle("Start another workout".localized(), for: UIControlState())
        button.addTarget(self, action: #selector(MRStartWorkoutViewController.selectAnotherWorkout), for: [.touchUpInside])
        scrollView.addSubview(button)
        
    }
    
    private func displayMainWorkout(_ sessionType: MRSessionType) {
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
        performSegue(withIdentifier: "manual", sender: nil)
    }
    
    @objc private func changeWorkout(_ sender: MRAlternativeWorkoutButton) {
        if let sessionType = sender.sessionType {
            displayMainWorkout(sessionType)
        }
    }
    
    /// MARK: MRCircleViewDelegate
    
    func circleViewTapped(_ circleView: MRCircleView) {
        if let sessionType = selectedSession {
            try! MRAppDelegate.sharedDelegate().startSession(sessionType)
        }
    }
    
}
