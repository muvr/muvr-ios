import Foundation

public enum MKRepetitionEstimatorError : ErrorType {
    
    case MissingAccelerometerType
    
}

public struct MKRepetitionEstimator {
    public typealias Estimate = (UInt8, Double)
    
    public func estimate(data data: MKSensorData) throws -> Estimate {
        fatalError()
    }
    
}

/*
@interface MRRepetitionEstimator : NSObject

// A characteristic profile of a periode of a signal
struct PeriodicProfile
{
// Abosolute amount the signal changed in the period
uint total_steps = 0;
// Upwards steps of the signal
uint upward_steps = 0;
// Downwards steps of the signal
uint downward_steps = 0;
};

//
// Estimate the number of exercise repetitions in the passed data
//
- (uint)estimate:(const std::vector<muvr::fused_sensor_data>&)data;

@end
*/