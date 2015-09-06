import Foundation

class MRExerciseSessionProgressViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    static let storyboardId: String = "MRExerciseSessionProgressViewController"

    @IBOutlet var tableView: UITableView!
 
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        fatalError("Implement me")
    }
}
