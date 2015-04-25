#import <Foundation/Foundation.h>

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
/// For now a naïve way to represent a classified exercise as a NSString
///
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
- (void)pushBack:(NSData *)data from:(uint8_t)location;

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
@end
