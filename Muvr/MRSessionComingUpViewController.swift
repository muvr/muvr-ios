import Foundation
import UIKit
import MuvrKit

protocol MRAlternateExerciseDelegate {
    func alternateExerciseSelected(exercise: MKIncompleteExercise)
}

class MRSessionComingUpViewController: UIViewController, UIPageViewControllerDataSource {

    @IBAction func unwindToComingUp(unwindSegue: UIStoryboardSegue) { }
    
    let pageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
    
    weak var session: MRManagedExerciseSession? = nil {
        didSet {
            createControllers()
        }
    }
    
    var delegate: MRAlternateExerciseDelegate? = nil {
        didSet {
            controllers.forEach { $0.delegate = delegate }
        }
    }
    
    private var controllers: [MRAlternateExercisesViewController] = []
    
    override func viewDidLoad() {
        pageViewController.dataSource = self
        pageViewController.view.frame = view.frame
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
    }
    
    private func createControllers() {
        let exercises = (session?.plannedExercises ?? []) + (session?.unplannedExercises ?? [])
        controllers.removeAll()
        exercises.enumerate().forEach { index, exercise in
            if index % MRAlternateExercisesViewController.exercisesPerPage == 0 {
                let controller = MRAlternateExercisesViewController()
                controller.delegate = self.delegate
                controllers.append(controller)
            }
            controllers.last?.exercises.append(exercise)
        }
        if !controllers.isEmpty {
            pageViewController.setViewControllers([controllers.first!], direction: .Forward, animated: true, completion: nil)
            pageViewController.didMoveToParentViewController(self)
        }
    }
    
    /// MARK : UIPageViewControllerDataSource
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let x = (controllers.indexOf { $0 === viewController }) {
            if x > 0 { return controllers[x - 1] }
        }
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let x = (controllers.indexOf { $0 === viewController }) {
            if x < controllers.count - 1 { return controllers[x + 1] }
        }
        return nil
    }
    
}

class MRAlternateExercisesViewController: UIViewController {
    
    static let exercisesPerPage = 3

    var exercises: [MKIncompleteExercise] = []
    
    var delegate: MRAlternateExerciseDelegate? = nil 
    
    override func viewDidLoad() {
        exercises.forEach { exercise in
            let button = MRAlternateExerciseButton()
            button.exercise = exercise
            button.addTarget(self, action: "exerciseSelected:", forControlEvents: UIControlEvents.TouchUpInside)
            view.addSubview(button)
        }
    }
    
    override func viewDidLayoutSubviews() {
        let width = view.frame.width / CGFloat(MRAlternateExercisesViewController.exercisesPerPage)
        let height = view.frame.height
        let spacing = width / 10
        view.subviews.enumerate().forEach { index, view in
            view.frame = CGRectMake(width * CGFloat(index) + spacing / 2, 0, width - spacing, height)
        }
    }
    
    func exerciseSelected(sender: UIButton?) {
        if let exercise = (sender as? MRAlternateExerciseButton)?.exercise {
            delegate?.alternateExerciseSelected(exercise)
        }
    }
    
    
}
