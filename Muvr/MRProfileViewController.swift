import Foundation
import MobileCoreServices

class MRProfileViewController : UITableViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var saveItem: UIBarItem!
    @IBOutlet var firstName: UITextField!
    @IBOutlet var lastName: UITextField!
    @IBOutlet var age: UITextField!
    @IBOutlet var weight: UITextField!
    @IBOutlet var profileImageView: UIImageView!
    
    override func viewDidLoad() {
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.layer.borderColor = view.tintColor.CGColor
        profileImageView.layer.borderWidth = 2
        profileImageView.clipsToBounds = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        MRApplicationState.loggedInState!.getPublicProfile { $0.getOrUnit(self.showProfile) }
        MRApplicationState.loggedInState!.getProfileImage { $0.getOrUnit(self.setProfileImage) }
    }
    
    private func setProfileImage(profileImage: NSData) {
        profileImageView.image = UIImage(data: profileImage)
    }
    
    private func showProfile(profile: MRPublicProfile?) {
        if let x = profile {
            firstName.text = x.firstName
            lastName.text = x.lastName
            if let a = x.age { age.text = String(a) }
            if let w = x.weight { weight.text = String(w) }
        }
    }

    private func setProfilePicture() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        presentViewController(imagePicker, animated: true, completion: nil)
    }

    func textFieldDidBeginEditing(textField: UITextField) {
        saveItem.enabled = true
    }
    
    @IBAction func save() {
        let pp = MRPublicProfile(firstName: firstName.text!, lastName: lastName.text!, weight: Int(weight.text!), age: Int(age.text!))
        MRApplicationState.loggedInState!.setPublicProfile(pp) { _ in
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            setProfilePicture()
        }
    }

    // MARK: UIImagePickerControllerDelegate implementation
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        let w: CGFloat = 200.0
        let h: CGFloat = 200.0
        var profileImage: NSData
        if image.size.width > w || image.size.height > h {
            let sx = w / CGFloat(image.size.width)
            let sy = h / CGFloat(image.size.height)
            let s = min(sx, sy)
            let newSize = CGSizeMake(image.size.width * s, image.size.height * s)
            UIGraphicsBeginImageContext(newSize)
            image.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            profileImage = UIImageJPEGRepresentation(scaledImage, 0.6)!
        } else {
            profileImage = UIImageJPEGRepresentation(image, 0.6)!
        }
        
        MRApplicationState.loggedInState!.setProfileImage(profileImage)
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
