#import <Foundation/Foundation.h>
#import "MuvrPreclassification/include/sensor_data.h"
#import "MuvrPreclassification/include/classifier.h"

typedef NSString MRExercise;

///
/// Actions executed as results of exercise
///
@protocol MRClassificationPipelineDelegate

///
/// Classification successful
///
- (void)classificationSucceeded;

///
/// Classification ambiguous
///
- (void)classificationAmbiguous;

///
/// Classification failed
///
- (void)classificationFailed;
@end

///
/// Interface to the C++ codebase implementing the classification pipeline code
///
@interface MRClassificationPipeline : NSObject

///
/// Constructs an instance, sets up the underlying native structures
///
- (instancetype)init;

///
/// Classify the session data
///
- (int)classify:(const muvr::fused_sensor_data &)data;

///
/// Sets the exercise block delegate, whose methods get called when entire exercise
/// block is detected.
///
@property id<MRClassificationPipelineDelegate> classificationPipelineDelegate;
@end