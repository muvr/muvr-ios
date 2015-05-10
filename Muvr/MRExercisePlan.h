#ifndef Muvr_MRExercisePlan_h
#define Muvr_MRExercisePlan_h
#import "MRPreclassification.h"

///
/// The rest for the given duration or hear rate
///
@interface MRRest : NSObject

/// the maximum rest duration
@property (readonly) NSTimeInterval duration;

/// the heart rate
@property (readonly) uint8_t hrBelow;
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
/// The exercise plan interface
///
@interface MRExercisePlan : NSObject

///
/// Construct this instance with the given array of ``MRResistanceExercise *`` instances, padding them
/// with ``MRRest *`` instances of the given ``duration``.
///
+ (instancetype)planWithResistanceExercises:(NSArray *)resistanceExercises andDefaultDuration:(uint)duration;

///
/// Construct ad-hoc exercise plan
///
+ (instancetype)adHoc;

///
/// Submit exercise, return array of ``MRExercisePlanItem *``s still to be done
///
- (NSArray *)exercise:(MRResistanceExercise *)actual;

///
/// Submit rest, return array of ``MRExercisePlanItem *``s still to be done
///
- (NSArray *)noExercise;

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

@end

#endif
