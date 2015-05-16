import Foundation

///
/// Profile cell shows the user's picture
///
class MRProfileImageTableViewCell : UITableViewCell {
    @IBOutlet
    var profileImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if profileImageView == nil { return }
        
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.layer.borderColor = tintColor.CGColor
        profileImageView.layer.borderWidth = 2
        profileImageView.clipsToBounds = true
    }
}

class MRProfileViewController : UITableViewController {
    
}
