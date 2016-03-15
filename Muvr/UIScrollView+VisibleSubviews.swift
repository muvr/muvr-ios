import UIKit

extension UIScrollView {

    ///
    /// the list of subviews currently visible inside this scrollview
    ///
    var visibleSubviews: [UIView] {
        let visibleArea = CGRectMake(contentOffset.x, contentOffset.y, frame.width, frame.height)
        return subviews.filter { $0.frame.height > 0 && CGRectIntersectsRect($0.frame, visibleArea) }
    }
    
}