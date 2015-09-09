#ifndef Muvr_MRClassifiedResistanceExercise_h
#define Muvr_MRClassifiedResistanceExercise_h

#import <Foundation/Foundation.h>

///
/// The classification result
///
@interface MRResistanceExercise : NSObject

///
/// Construct this instance with unknown intensity, repetitions and weight
///
- (instancetype)initWithId:(NSString *)id;

/// the classified exercise
@property (readonly) NSString *id;
@end

@interface MRClassifiedResistanceExercise : NSObject

- (instancetype)init:(MRResistanceExercise *)exercise;

- (instancetype)initWithResistanceExercise:(MRResistanceExercise *)resistanceExercise
                               repetitions:(NSNumber *)repetitions
                                    weight:(NSNumber *)weight
                                 intensity:(NSNumber *)intensity
                                      time:(uint)time
                             andConfidence:(double)confidence;

@property (readonly) MRResistanceExercise* resistanceExercise;
/// if != nil, the number of repetitions
@property (readonly) NSNumber *repetitions;
/// if != nil, the weight
@property (readonly) NSNumber *weight;
/// if != nil, the intensity
@property (readonly) NSNumber *intensity;
/// the confidence
@property (readonly) double confidence;
/// the time spent exercising in seconds
@property (readonly) uint time;

@end



#endif
