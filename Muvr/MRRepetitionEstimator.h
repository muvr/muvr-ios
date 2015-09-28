#ifndef MRRepetitionEstimator_h
#define MRRepetitionEstimator_h

#import <Foundation/Foundation.h>
#import "MuvrPreclassification/include/sensor_data.h"

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

#endif /* MRRepetitionEstimator_h */
