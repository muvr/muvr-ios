#ifndef MRRepetitionEstimator_h
#define MRRepetitionEstimator_h

#import <Foundation/Foundation.h>
#import "MuvrPreclassification/include/sensor_data.h"

@interface MRRepetitionsEstimator : NSObject

- (uint)estimate:(const std::vector<muvr::fused_sensor_data>&)data;

@end

#endif /* MRRepetitionEstimator_h */
