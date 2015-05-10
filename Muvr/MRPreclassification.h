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
/// The classification result
///
@interface MRResistanceExercise : NSObject
- (instancetype)initWithExercise:(NSString *)exercise
                   andConfidence:(double) confidence;

- (instancetype)initWithExercise:(NSString *)exercise
                     repetitions:(NSNumber *)repetitions
                          weight:(NSNumber *)weight
                       intensity:(NSNumber *)intensity
                   andConfidence:(double)confidence;

/// if != nil, the number of repetitions
@property (readonly) NSNumber *repetitions;
/// if != nil, the weight
@property (readonly) NSNumber *weight;
/// if != nil, the intensity
@property (readonly) NSNumber *intensity;
/// the classified exercise
@property (readonly) NSString *exercise;
/// the classification confidence
@property (readonly) double confidence;
@end

///
/// The classified exercise set. In most cases, the ``sets`` property will contain only one entry.
/// However, some users may do drop-sets (the same exercise with decreasing weight), super-sets
/// any many other tortures.
///
@interface MRResistanceExerciseSet : NSObject

/// Initializes this instance with just one exercise in a set
- (instancetype)init:(MRResistanceExercise *)exercise;

/// Initializes this instance with the given ``sets``
- (instancetype)initWithSets:(NSArray *)sets;

/// computes the overall confidence for this set
- (double)confidence;

/// retrieves the given set at the index
- (MRResistanceExercise *)objectAtIndexedSubscript:(int)idx;
/// the exercise sets, containing ``MRClassifiedExercise``
@property (readonly) NSArray *sets;
@end

///
/// Actions executed as results of exercise
///
@protocol MRClassificationPipelineDelegate

///
/// Classification successful, ``result`` holds elements of type ``MRClassifiedExerciseSet``. The
/// implementation of this delegate should examine the array and decide what to do depending on
/// the size of the array. The ``data`` value holds the exported ``muvr::fused_sensor_data`` that
/// was used for the classification.
///
- (void)classificationCompleted:(NSArray *)result fromData:(NSData *)data;

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
- (void)pushBack:(NSData *)data from:(uint8_t)location withHint:(MRResistanceExercise *)plannedExercise;

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
