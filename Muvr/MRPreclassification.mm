#import "MRPreclassification.h"

#pragma MARK - Threed implementation

@implementation Threed
@end

@implementation MRPreclassification

+ (instancetype)training {
    return [[MRPreclassification alloc] initWithModel:nil];
}

+ (instancetype)classifying:(MRModelParameters *)model {
    return [[MRPreclassification alloc] initWithModel:model];
}

- (instancetype)initWithModel:(MRModelParameters *)model {
    self = [super init];
    
    return self;
}

- (void)pushBack:(NSData *)data from:(uint8_t)location withHint:(MRResistanceExercise *)plannedExercise {
}

- (void)exerciseCompleted {
}

- (void)trainingCompleted {
}

- (void)trainingStarted:(MRResistanceExercise *)exercise {
}

@end
