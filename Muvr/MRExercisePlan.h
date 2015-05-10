#ifndef Muvr_MRExercisePlan_h
#define Muvr_MRExercisePlan_h
#import "MRPreclassification.h"

//@interface MRRest : NSObject
//@property (readonly) NSTimeInterval duration;
//@property (readonly) uint8_t hrBelow;
//@end
//
//@interface MRNextResistanceExercise
//@property (readonly) MRResistanceExercise *exercise;
//@property (readonly) MRRest *rest;
//@end

@interface MRExercisePlan : NSObject

- (instancetype)initWithResistanceExercises:(NSArray *)resistanceExercises andDefaultRestDuration:(uint)duration;

- (NSArray *)exercise:(MRResistanceExercise *)actual;

- (NSArray *)rest;

- (NSArray *)completed;

- (NSArray *)deviations;

- (NSArray *)todo;

- (double)progress;

@end

#endif
