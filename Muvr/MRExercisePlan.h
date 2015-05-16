#ifndef Muvr_MRExercisePlan_h
#define Muvr_MRExercisePlan_h
#import "MRPreclassification.h"

///
/// The rest for the given duration or hear rate
///
@interface MRRest : NSObject

/// the minimum rest duration
@property (readonly) NSTimeInterval minimumDuration;

/// the maximum duration
@property (readonly) NSTimeInterval maximumDuration;

/// the heart rate
@property (readonly) uint8_t minimumHeartRate;
@end

///
/// The exercise plan item is a grouping of one of non nil properties
///
@interface MRExercisePlanItem : NSObject
/// If != nil, the resistance exercise
@property (readonly) MRResistanceExercise* resistanceExercise;
/// If != nil, the rest
@property (readonly) MRRest* rest;
@end

///
/// Deviation from the exercise plan
///
@interface MRExercisePlanDeviation : NSObject
/// The actual item
@property (readonly) MRExercisePlanItem* actual;
/// The planned item
@property (readonly) MRExercisePlanItem* planned;
@end

///
/// Exercise plan delegate
///
@protocol MRExercisePlanDelegate

///
/// Called when the current item changes
///
- (void)currentItem:(MRExercisePlanItem *)item changedFromPrevious:(MRExercisePlanItem *)previous;

@end

///
/// The exercise plan interface
///
@interface MRExercisePlan : NSObject

///
/// Construct this instance with the given array of ``MRResistanceExercise *`` instances, padding them
/// with ``MRRest *`` instances of the given ``duration``.
///
+ (instancetype)planWithResistanceExercises:(NSArray *)resistanceExercises;

///
/// Construct ad-hoc exercise plan
///
+ (instancetype)adHoc;

///
/// Submit exercise, return the ``MRExercisePlanItem *`` that the user is expected to be doing
///
- (MRExercisePlanItem *)exercise:(MRResistanceExercise *)actual;

///
/// Submit rest, return the ``MRExercisePlanItem *`` that the user is expected to be doing
///
- (MRExercisePlanItem *)noExercise;

///
/// The ``MRExercisePlanItem *`` that the user is expected to be doing
///
@property (readonly) MRExercisePlanItem* current;

///
/// Return array of ``MRExercisePlanItem *``s that have already been done
///
@property (readonly) NSArray * completed;

///
/// Return array of ``MRExercisePlanDeviation *``s
///
@property (readonly) NSArray * deviations;

///
/// Submit rest, return array of ``MRExercisePlanItem *``s still to be done
///
@property (readonly) NSArray * todo;

///
/// Return the progress through the plan (0..1)
///
@property (readonly) double progress;

///
/// The exercise plan delegate
///
@property id<MRExercisePlanDelegate> delegate;

@end

#endif
