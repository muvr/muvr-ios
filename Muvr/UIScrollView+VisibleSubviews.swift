import UIKit

extension UIScrollView {

    ///
    /// the list of subviews currently visible inside this scrollview
    ///
    var visibleSubviews: [UIView] {
        let visibleArea = CGRect(x: contentOffset.x, y: contentOffset.y, width: frame.width, height: frame.height)
        return subviews.filter { $0.frame.height > 0 && $0.frame.intersects(visibleArea) }
    }
    
}
