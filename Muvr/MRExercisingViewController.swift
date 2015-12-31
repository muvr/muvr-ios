import UIKit

class MRExercisingViewController : UIViewController, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var timedView: MRTimedView!

    override func viewDidLoad() {
        timedView.setColourScheme(MRColourSchemes.amber)
        timedView.elapsedResets = true
    }
    
    override func viewDidAppear(animated: Bool) {
        timedView.start(5, onTimerElapsed: beginExercising)
    }
    
    private func beginExercising(tv: MRTimedView) {
        timedView.setColourScheme(MRColourSchemes.red)
        timedView.setButtonTitle("stop")
        timedView.buttonTouched = stopExercising
    }
    
    private func stopExercising(tv: MRTimedView) {
        timedView.setColourScheme(MRColourSchemes.green)
        timedView.setButtonTitle("✓")
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        fatalError()
    }
    
}
