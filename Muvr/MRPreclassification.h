#import <Foundation/Foundation.h>

@protocol MRDeviceDataDelegate

//- (void)deviceDataDecoded:(uint16_t **)memory rows:(int)rows cols:(int)cols;
- (void)deviceDataDecoded:(NSArray *)rows;

@end

///
/// The most coarse exercise detection
///
@protocol MRExerciseBlockDelegate

///
/// Movement detected consistent with some specific exercise.
///
- (void)exercising;

///
/// The exercise block has ended: either because there is no movement, or the exercise
/// movement became too divergent.
///
- (void)exerciseEnded;

- (void)moving;

- (void)notMoving;

@end

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
/// Interface to the C++ codebase implementing the preclassification code
///
@interface MRPreclassification : NSObject

///
/// Constructs an instance, sets up the underlying native structures
///
- (instancetype)init;

///
/// Push back the data received from the device at the given location and time
///
- (void)pushBack:(NSData *)data from:(int)location at:(CFAbsoluteTime)time;

///
/// Sets the exercise block delegate, whose methods get called when entire exercise
/// block is detected.
///
@property id<MRExerciseBlockDelegate> exerciseBlockDelegate;
@property id<MRDeviceDataDelegate> deviceDataDelegate;
@property id<MRClassificationPipelineDelegate> classificationPipelineDelegate;
@end
