import Foundation

extension MRRest {
    
    func marshal() -> [String : AnyObject] {
        return ["minimumDuration":minimumDuration,
                "maximumDuration":maximumDuration,
                "minimumumHeartRate":NSNumber(uint8: minimumHeartRate)]
    }
    
}
