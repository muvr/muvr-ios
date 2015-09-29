#ifndef Muvr_MRMultilayerPerceptron_h
#define Muvr_MRMultilayerPerceptron_h

#import "MuvrPreclassification/include/sensor_data.h"
#import "MRModelParameters.h"

using namespace muvr;

///
/// Interface to the MLP implementing classification
///
@interface MRMultilayerPerceptron : NSObject

///
/// Size of the steps between two classification attempts. Classifier will fuse the results of all windows.
///
@property uint windowStepSize;

///
/// Constructs an instance, sets up the underlying native structures loading the model
/// from file
///
- (instancetype)initWithModel:(MRModelParameters *)model;

///
/// Classify the passed data, returns ``NSArray*`` of ``MRClassifiedResistanceExercise``.
///
-  (NSArray *)classify:(const std::vector<fused_sensor_data> &)data withMaximumResults:(uint)numberOfResults repetitionHint:(NSNumber*)repetitions;
@end

#endif
