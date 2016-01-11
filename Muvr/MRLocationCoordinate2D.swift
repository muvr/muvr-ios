import Foundation

///
/// Protocol that encodes the 2D coordinates. It matches the CoreLocation struct
/// and some of our ``MRManaged*`` classes.
///
protocol MRLocationCoordinate2D {
    /// The longitude in degrees
    var longitude: Double { get }
    /// The latitude in degrees
    var latitude: Double { get }
}
