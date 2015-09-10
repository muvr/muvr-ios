#import <Foundation/Foundation.h>
#import "MRModelParameters.h"
#import "MRClassifiedResistanceExercise.h"

///
/// Object holding triple of X, Y, Z values typical for three-dimensional
/// sensors.
///
@interface Threed : NSObject
/// the x component
@property int16_t x;
/// the y component
@property int16_t y;
/// the z component
@property int16_t z;
@end

///
/// Hooks into the decoding of the data from the various devices
///
@protocol MRDeviceDataDelegate

///
/// Called when decoded 3D structure from the given ``sensor``, ``device`` at the ``location``. The ``rows`` is an array of
/// ``Threed*`` instances
///
- (void)deviceDataDecoded3D:(NSArray *)rows fromSensor:(uint8_t)sensor device:(uint8_t)deviceId andLocation:(uint8_t)location;

///
/// Called when decoded 3D structure from the given ``sensor``, ``device`` at the ``location``. The ``rows`` is an array of
/// ``NSNumber*`` instances holding ``int16_t``.
///
- (void)deviceDataDecoded1D:(NSArray *)rows fromSensor:(uint8_t)sensor device:(uint8_t)deviceId andLocation:(uint8_t)location;

@end

///
/// The most coarse exercise detection
///
@protocol MRExerciseBlockDelegate

///
/// Movement detected consistent with some exercise.
///
- (void)exercising;

///
/// The exercise block has ended: either because there is no movement, or the exercise
/// movement became too divergent.
///
- (void)exerciseEnded;

///
/// Movement detected; this movement may become exercise.
///
- (void)moving;

///
/// No movement detected.
///
- (void)notMoving;

@end

///
/// Actions executed as results of exercise
///
@protocol MRClassificationPipelineDelegate

///
/// Classification successful, ``result`` holds elements of type ``MRClassifiedExercise``. The
/// implementation of this delegate should examine the array and decide what to do depending on
/// the size of the array. The ``data`` value holds the exported ``muvr::fused_sensor_data`` that
/// was used for the classification.
///
- (void)classificationCompleted:(NSArray *)result fromData:(NSData *)data;

///
/// Classification made some decisions, but this is not the final decision. The final decision will
/// arrive in the ``classificationCompleted:fromData:`` call.
///
/// This method provides a way to provide a view on the in-progress classification.
///
- (void)classificationEstimated:(NSArray *)result;

///
/// Called when the classifier has estimated the number of repetitions.
///
- (void)repetitionsEstimated:(uint)repetitions;

@end

///
/// Actions executed as results of training
///
@protocol MRTrainingPipelineDelegate

///
/// Classification successful, ``result`` holds elements of type ``MRClassifiedExerciseSet``. The
/// implementation of this delegate should examine the array and decide what to do depending on
/// the size of the array. The ``data`` value holds the exported ``muvr::fused_sensor_data`` that
/// was used for the classification.
///
- (void)trainingCompleted:(MRResistanceExercise *)exercise fromData:(NSData *)data;

@end

///
/// Interface to the C++ codebase implementing the preclassification code
///
@interface MRPreclassification : NSObject


///
/// Constructs an instance, sets up the underlying native structures
///
+ (instancetype)training;

///
/// Constructs an instance, sets up the underlying native structures
///
+ (instancetype)classifying:(MRModelParameters *)model;

///
/// Push back the data received from the device at the given location and time
///
- (void)pushBack:(NSData *)data from:(uint8_t)location withHint:(MRResistanceExercise *)plannedExercise;

///
/// Marks the start of the training session for the given exercise
///
- (void)trainingStarted:(MRResistanceExercise *)exercise;

///
/// Marks the end of the training block
///
- (void)trainingCompleted;

///
/// Marks the end of the exercise block
///
- (void)exerciseCompleted;

///
/// exercise block delegate, whose methods get called when entire exercise block is detected.
///
@property id<MRExerciseBlockDelegate> exerciseBlockDelegate;

///
/// provides hooks to be notified of device data arriving / decoding progress
///
@property id<MRDeviceDataDelegate> deviceDataDelegate;

///
/// provides hooks into the classification pipeline
///
@property id<MRClassificationPipelineDelegate> classificationPipelineDelegate;

///
/// provides hooks into the training pipeline
///
@property id<MRTrainingPipelineDelegate> trainingPipelineDelegate;
@end
