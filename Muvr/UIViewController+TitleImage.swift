import UIKit

///
/// Allows to set an image as title
///
extension UIViewController {

    ///
    /// Sets the given image as title in the navigation bar
    /// - parameter named: the image name
    ///
    func setTitleImage(named imageName: String) {
        if let navFrame = navigationController?.navigationBar.frame {
            let height = navFrame.height - 4
            let width = height * 1.6
            let frame = CGRect(x: (navFrame.width - width) / 2, y: 2, width: width, height: height)
            let view = UIImageView(frame: frame)
            view.image = UIImage(named: imageName)
            view.contentMode = .scaleAspectFit
            navigationItem.titleView = view
        }
    }
    
}
