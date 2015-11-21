import WatchKit

protocol MRSessionProgressRing {

    var titleLabel: WKInterfaceLabel! { get }
    
    var outerRing: WKInterfaceGroup! { get }
    var innerRing: WKInterfaceGroup! { get }
    var ringLabel: WKInterfaceLabel! { get }
    var timeLabel: WKInterfaceLabel! { get }
    var sessionLabel: WKInterfaceLabel! { get }
    
}