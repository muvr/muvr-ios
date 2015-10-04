import Foundation

public typealias MKIntensityId = UInt

public struct MKIntensity {
    public let id: MKIntensityId
    public let title: String
    public let restDuration: NSTimeInterval
    public let heartRateRange: (Double, Double)
    
    public init(id: MKIntensityId, title: String, restDuration: NSTimeInterval, heartRateRange: (Double, Double)) {
        self.id = id
        self.title = title
        self.restDuration = restDuration
        self.heartRateRange = heartRateRange
    }
}
