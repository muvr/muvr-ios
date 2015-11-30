import WatchKit

protocol MRSessionHealth {

    var heartGroup: WKInterfaceGroup! { get }
    var heartLabel: WKInterfaceLabel! { get }
    var energyGroup: WKInterfaceGroup! { get }
    var energyLabel: WKInterfaceLabel! { get }
    
}