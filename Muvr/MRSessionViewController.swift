import UIKit
import MuvrKit
import AVFoundation

///
/// The session view controller displays the session in progress
///
class MRSessionViewController : UIViewController, MRCircleViewDelegate {
    
    @IBOutlet weak var labSwitch: UISwitch!
    @IBOutlet weak var labLabel: UILabel!
    @IBOutlet weak var predictionProbabilityLabel: UILabel!
    
    @IBOutlet weak var repsCounter: UILabel!
    var currentRepsCount: Int = 0
    var repsCounterAccumulator: Int = 0
    
    let defaults = UserDefaults.standard()

    /// Wait before acepting new detected exercises to avoid too quick view switch
    private var lastUpdatedTime = Date()
    private let setupExerciseWindow = 5.0

    @IBAction func labSwitchPressed(_ sender: AnyObject) {
        defaults.set(labSwitch.isOn, forKey: "labMode")
        setLabModeLabel()
    }

    private func setLabModeLabel() {
        if labSwitch.isOn {
            labLabel.text = "Lab Mode On"
            predictionProbabilityLabel.isHidden = false
        } else {
            labLabel.text = "Lab Mode Off"
            predictionProbabilityLabel.isHidden = true
        }
    }

    func setReps(_ reps: Int) {
        repsCounter.text = "\(reps)"
        currentRepsCount = reps
    }
    
    func resetResp() {
        repsCounter.text = ""
        repsCounterAccumulator = 0
        currentRepsCount = 0
    }
    
    /// The current selected exercise along with predicted labels
    private struct CurrentExercise {
        /// the selected exercise details
        let detail: MKExerciseDetail
        /// the predicted labels
        let predicted: MKExerciseLabelsWithDuration
        /// the default values for unpredicted labels
        let missing: MKExerciseLabelsWithDuration
        
        var labels: [MKExerciseLabel] {
            return predicted.0 + missing.0
        }
        
        var duration: TimeInterval? {
            return predicted.1 ?? missing.1
        }
        
        var rest: TimeInterval? {
            return predicted.2 ?? missing.2
        }
    }
    
    /// The state this controller is in
    private enum State {
        /// The user selects his next ``exercise``
        /// - parameter exercise: the selected exercise
        /// - parameter rest: the rest duration
        case comingUp(exercise: CurrentExercise?, rest: TimeInterval?)
        /// The user should get ready to start the given ``exercise``
        /// - parameter exercise: the selected exercise
        /// - parameter rest: the rest duration
        case ready(exercise: CurrentExercise, rest: TimeInterval?)
        /// The user should get the setup position for the given ``exercise``
        /// - parameter exercise: the selected exercise
        /// - parameter start: the start date
        case setup(exercise: CurrentExercise, rest: TimeInterval?)
        /// The user is exercising
        /// - parameter exercise: the selected exercise
        /// - parameter start: the start date
        case inExercise(exercise: CurrentExercise, start: Date)
        /// The user has finished exercising
        /// - parameter exercise: the finished exercise
        /// - parameter labels: the labels
        /// - parameter start: the start date
        /// - parameter duration: the duration
        case done(exercise: CurrentExercise, labels: [MKExerciseLabel], start: Date, duration: TimeInterval)
        /// The session is over (fix long press callback)
        case idle
        
        var color: UIColor {
            switch self {
            case .comingUp: return UIColor.green()
            case .ready: return UIColor.orange()
            case .setup: return UIColor.purple()
            case .inExercise: return UIColor.red()
            case .done: return UIColor.gray()
            case .idle: return UIColor.clear()
            }
        }
        
    }
    
    /// The circle that displays an exercise and a round bar
    @IBOutlet private weak var mainExerciseView: MRCircleExerciseView!
    
    /// The session–in–progress
    private var session: MRManagedExerciseSession!
    /// The current state
    private var state: State = .comingUp(exercise: nil, rest: nil)
    
    /// The details view controllers
    private var comingUpViewController: MRSessionComingUpViewController!
    private var readyViewController: UIViewController!
    private var setupViewController: UIViewController!
    private var inExerciseViewController: UIViewController!
    private var labellingViewController: MRSessionLabellingViewController!
    
    private var comingUpExerciseDetails: [MKExerciseDetail] = []

    /// The list of alternatives exercises
    private var alternatives: [MKExerciseDetail] {
        guard case .comingUp(let currentExercise, _) = state, let selected = currentExercise?.detail ?? comingUpExerciseDetails.first else { return [] }
        let visibleExerciseIds = comingUpViewController.visibleExerciseDetails.map { $0.id }
        return comingUpExerciseDetails.filter { $0.isAlternativeOf(selected) && (selected.id == $0.id || !visibleExerciseIds.contains($0.id)) }
    }
    
    ///
    /// Sets the session to be displayed by this controller
    /// - parameter session: the session
    ///
    func setSession(_ session: MRManagedExerciseSession) {
        self.session = session
    }

    func exerciseSetupDetected(_ label: String, probability: Double) {
        if labSwitch.isOn {
            mainExerciseView?.headerTitle = label.components(separatedBy: "/").last
            let probabilityString = String(format: "%.2f", probability*100)
            predictionProbabilityLabel.text = "%\(probabilityString)"
        } else {
            switch state {
            case .comingUp(let exercise, _):
                if probability < 0.7 || exercise?.detail.id != label {
                    break
                }
                if Date().timeIntervalSince(lastUpdatedTime) < setupExerciseWindow {
                    break
                }
                state = .inExercise(exercise: exercise!, start: Date())
                refreshViewsForState(state)
            default:
                break
            }
        }
    }
    
    func repsCountFeed(_ reps: Int, start: Date, end: Date) {
        switch state {
        case .inExercise(let exercise, _):
            let accumulatedRepsCount = reps + repsCounterAccumulator
            //TODO: This hack is to avoid calculation errors on bigger windows. Should be fixed!
            if end.timeIntervalSince(start) > 10 {
                MRAppDelegate.sharedDelegate().exerciseStarted(exercise.detail, start: end)
                repsCounterAccumulator = accumulatedRepsCount
            }
            if currentRepsCount < accumulatedRepsCount {
                setReps(accumulatedRepsCount)
            }
        default:
            resetResp()
        }
    }

    override func viewDidLoad() {
        mainExerciseView.delegate = self
        labSwitch.isOn = defaults.bool(forKey: "labMode")
        setLabModeLabel()
        resetResp()
        
        setTitleImage(named: "muvr_logo_white")
        navigationItem.setHidesBackButton(true, animated: false)
        
        UIView.whenContained(inInstancesOfClasses: [MRSessionViewController.self]).tintColor = MRColor.black
        
        comingUpViewController = storyboard!.instantiateViewController(withIdentifier: "ComingUpViewController") as! MRSessionComingUpViewController
        readyViewController = storyboard!.instantiateViewController(withIdentifier: "ReadyViewController")
        setupViewController = storyboard!.instantiateViewController(withIdentifier: "ReadyViewController")
        inExerciseViewController = storyboard!.instantiateViewController(withIdentifier: "InExerciseViewController")
        labellingViewController = storyboard!.instantiateViewController(withIdentifier: "LabellingViewController") as! MRSessionLabellingViewController

    }
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default().addObserver(self, selector: #selector(MRSessionViewController.sessionDidStartExercise), name: MRNotifications.SessionDidStartExercise.rawValue, object: nil)
        NotificationCenter.default().addObserver(self, selector: #selector(MRSessionViewController.sessionDidEndExercise), name: MRNotifications.SessionDidEndExercise.rawValue, object: nil)
        refreshViewsForState(state)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default().removeObserver(self)
    }

    ///
    /// Updates the main title and the detail controller according the ``state``.
    /// - parameter state: the state to be displayed
    ///
    private func refreshViewsForState(_ state: State) {
        mainExerciseView.progressFullColor = state.color
        switch state {
        case .comingUp(_, let rest):
            comingUpExerciseDetails = session.exerciseDetailsComingUp
            mainExerciseView.headerTitle = "Coming up".localized()
            selectedExerciseDetail(comingUpExerciseDetails.first!)
            mainExerciseView.reset()
            let restDuration = rest ?? 60
            mainExerciseView.start(max(5, restDuration - 5)) // remove the 5s of the get ready countdown from rest duration
            switchToViewController(comingUpViewController, fromRight: false) {
                self.mainExerciseView.swipeButtonsHidden = self.alternatives.count < 2
            }
            comingUpViewController.setExerciseDetails(comingUpExerciseDetails, onSelected: selectedExerciseDetail)
        case .ready:
            mainExerciseView.headerTitle = "Get ready for".localized()
            mainExerciseView.swipeButtonsHidden = true
            mainExerciseView.reset()
            mainExerciseView.start(5)
            switchToViewController(setupViewController)
        case .setup:
            mainExerciseView.headerTitle = "Setup for exercise".localized()
            mainExerciseView.swipeButtonsHidden = true
            mainExerciseView.reset()
            mainExerciseView.start(5)
        case .inExercise(let exercise, let start):
            mainExerciseView.headerTitle = "Stop".localized()
            mainExerciseView.reset()
            mainExerciseView.start(exercise.duration!)
            try! MRAppDelegate.sharedDelegate().exerciseStarted(exercise.detail, start: start)
            switchToViewController(inExerciseViewController)
        case .done(let exercise, _, _, _):
            mainExerciseView.headerTitle = "Finished".localized()
            mainExerciseView.reset()
            mainExerciseView.start(15)
            switchToViewController(labellingViewController)
            labellingViewController.setExerciseDetail(exercise.detail, predictedLabels: exercise.predicted.0, missingLabels: exercise.missing.0, onLabelsUpdated: labelUpdated)
        case .idle: break;
        }
        lastUpdatedTime = Date()
    }
    
    ///
    /// Show the given ``controller`` in the container pane; below the main button.
    /// The first controller appears from below.
    ///
    /// - parameter controller: the controller whose view is to be displayed in the container
    /// - parameter fromRight: true if the new controller appears from the right of the screen
    ///
    private func switchToViewController(_ controller: UIViewController, fromRight: Bool = true, completion: ((Void) -> Void)? = nil) {
        /// The frame where the details view are displayed (takes all available space below the main circle view)
        let y = mainExerciseView.frame.origin.y + mainExerciseView.frame.height
        let frame = CGRect(x: 0, y: y, width: view.bounds.width, height: view.bounds.height - y)
        
        if let previousController = childViewControllers.first {
            let leftFrame = CGRect(x: -frame.width, y: frame.origin.y, width: frame.width, height: frame.height)
            let rightFrame = CGRect(x: frame.width, y: frame.origin.y, width: frame.width, height: frame.height)
            controller.view.frame = fromRight ? rightFrame : leftFrame
            
            addChildViewController(controller)
            previousController.willMove(toParentViewController: nil)
            
            transition(
                from: previousController,
                to: controller,
                duration: 0.4,
                options: [],
                animations: {
                    controller.view.frame = frame
                    previousController.view.frame = fromRight ? leftFrame : rightFrame
                }, completion: { finished in
                    previousController.removeFromParentViewController()
                    controller.didMove(toParentViewController: self)
                    if let comp = completion where finished { comp() }
                }
            )
        } else {
            let belowFrame = CGRect(x: frame.origin.x, y: frame.origin.y + frame.height, width: frame.width, height: frame.height)
            addChildViewController(controller)
            controller.willMove(toParentViewController: self)
            controller.view.frame = belowFrame
            controller.beginAppearanceTransition(true, animated: true)
            view.addSubview(controller.view)
            UIView.animate(withDuration: 0.2,
                animations: {
                    controller.view.frame = frame
                }, completion: { finished in
                    controller.didMove(toParentViewController: self)
                    controller.endAppearanceTransition()
                    if let comp = completion where finished { comp() }
                }
            )
        }
    }
    
    /// Called when the label is updated by the subcontroller
    /// - parameter newExercise: the updated label
    private func labelUpdated(_ newLabels: [MKExerciseLabel]) {
        mainExerciseView.reset()
        if case .done(let exercise, _, let start, let duration) = state {
            state = .done(exercise: exercise, labels: newLabels, start: start, duration: duration)
        }
    }
    
    /// Called when an exercise is selected
    /// - parameter exercise: the selected exercise
    private func selectedExerciseDetail(_ selectedExerciseDetail: MKExerciseDetail) {
        guard case .comingUp(_, let rest) = state else { return }
        mainExerciseView.exerciseDetail = selectedExerciseDetail
        let (predicted, missing) = session.predictExerciseLabelsForExerciseDetail(selectedExerciseDetail)
        let currentExercise = CurrentExercise(detail: selectedExerciseDetail, predicted: predicted, missing: missing)
        mainExerciseView.exerciseLabels = currentExercise.predicted.0
        mainExerciseView.exerciseDuration = currentExercise.predicted.1
        mainExerciseView.swipeButtonsHidden = alternatives.count < 2
        state = .comingUp(exercise: currentExercise, rest: rest)
    }
    
    // MARK: - MRCircleViewDelegate
    
    func circleViewLongTapped(_ exerciseView: MRCircleView) {
        if case .comingUp = state {
            try! MRAppDelegate.sharedDelegate().endCurrentSession()
            state = .idle
        }
    }
    
    func circleViewTapped(_ exerciseView: MRCircleView) {
        switch state {
        case .comingUp(let exercise, let rest):
            // The user has tapped on the exercise. Let's get ready
            state = .ready(exercise: exercise!, rest: rest)
        case .ready(let exercise, let rest):
            state = .comingUp(exercise: exercise, rest: rest)
        case .setup(let exercise, let rest):
            state = .comingUp(exercise: exercise, rest: rest)
        case .inExercise(let exercise, let start):
            state = .done(exercise: exercise, labels: exercise.labels, start: start, duration: Date().timeIntervalSince(start))
            session.clearClassificationHints()
        case .done(let exercise, let labels, let start, let duration):
            // The user has completed the exercise, and accepted our labels
            session.addExerciseDetail(exercise.detail, labels: labels, start: start, duration: duration)
            state = .comingUp(exercise: nil, rest: exercise.rest)
        case .idle: break
        }
        refreshViewsForState(state)
    }
    
    func circleViewCircleDidComplete(_ exerciseView: MRCircleView) {
        switch state {
        case .comingUp:
            // We've exhausted our rest time. Turn orange to give the user a kick.
            mainExerciseView.progressFullColor = MRColor.orange
        case .ready(let exercise, _):
            // We've had the time to get ready. Now time to get setup.
            session.setClassificationHint(exercise.detail, labels: exercise.predicted.0)
            if labSwitch.isOn {
                state = .setup(exercise: exercise, rest: nil)
            } else {
                state = .inExercise(exercise: exercise, start: Date())
            }
            refreshViewsForState(state)
        case .setup(let exercise, _):
            // We've had the time to get setup. Now time to exercise.
            session.setClassificationHint(exercise.detail, labels: exercise.predicted.0)
            state = .inExercise(exercise: exercise, start: Date())
            refreshViewsForState(state)
        case .done(let exercise, let labels, let start, let duration):
            // The user has completed the exercise, modified our labels, and accepted.
            session.addExerciseDetail(exercise.detail, labels: labels, start: start, duration: duration)
            state = .comingUp(exercise: nil, rest: exercise.rest)
            refreshViewsForState(state)
        default: return
        }
    }
    
    func circleViewSwiped(_ exerciseView: MRCircleView, direction: UISwipeGestureRecognizerDirection) {
        guard case .comingUp(let exercise, _) = state, let selected = exercise?.detail ?? comingUpExerciseDetails.first else { return }
        
        let index = alternatives.index { selected.id == $0.id } ?? 0
        let length = alternatives.count
        
        func next() -> Int? {
            guard length > 0 else { return nil }
            if direction == .left { return (index + 1) % length }
            if direction == .right { return (index - 1 + length) % length }
            return nil
        }
        
        guard let n = next() else { return }
        selectedExerciseDetail(alternatives[n])
    }

    /// Notification selector on exercise did end
    @objc private func sessionDidEndExercise() {
        if case .inExercise(let exercise, let start) = state {
            state = .done(exercise: exercise, labels: exercise.labels, start: start, duration: Date().timeIntervalSince(start))
            session.clearClassificationHints()
            refreshViewsForState(state)
        }
    }

    /// Notification selector on exercise did start
    @objc private func sessionDidStartExercise() {
        if case .comingUp(let .some(exercise), _) = state {
            session.setClassificationHint(exercise.detail, labels: exercise.predicted.0)
            state = .inExercise(exercise: exercise, start: Date())
            refreshViewsForState(state)
        }
    }
    
}
