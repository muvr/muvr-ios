#import "MRClassifiedResistanceExercise.h"

#pragma MARK - MRResistanceExercise implementation

@implementation MRResistanceExercise

- (instancetype)initWithId:(NSString *)id {
    self = [super init];
    _id = id;
    return self;
}

@end

#pragma MARK - MRClassifiedResistanceExercise implementation

@implementation MRClassifiedResistanceExercise

- (instancetype)init:(MRResistanceExercise *)resistanceExercise {
    self = [super init];
    _resistanceExercise = resistanceExercise;
    return self;
}

- (instancetype)initWithResistanceExercise:(MRResistanceExercise *)resistanceExercise
                               repetitions:(NSNumber *)repetitions
                                    weight:(NSNumber *)weight
                                 intensity:(NSNumber *)intensity
                                      time:(uint)time
                             andConfidence:(double)confidence {
    self = [super init];
    _resistanceExercise = resistanceExercise;
    _repetitions = repetitions;
    _weight = weight;
    _intensity = intensity;
    _confidence = confidence;
    _time = time;
    return self;
}

@end
