#import <Foundation/Foundation.h>
#import "MRExercisePlan.h"
#import "MuvrPreclassification/include/exercise_plan.h"

using namespace muvr;

@implementation MRResistanceExercise (planned_exercise)

+ (instancetype)plannedExercise:(const planned_exercise &)plannedExercise {
    assert(plannedExercise.tag == planned_exercise::resistance);
    auto rex = plannedExercise.resistance_exercise;
    
    NSString* exercise = [NSString stringWithUTF8String:plannedExercise.exercise.c_str()];
    NSNumber* repetitions = rex.repetitions != UNKNOWN_REPETITIONS ? [NSNumber numberWithInt:rex.repetitions] : nil;
    NSNumber* intensity = rex.intensity > UNKNOWN_INTENSITY ? [NSNumber numberWithDouble:rex.intensity] : nil;
    NSNumber* weight = rex.weight > UNKNOWN_WEIGHT ? [NSNumber numberWithDouble:rex.weight] : nil;
    
    return [[MRResistanceExercise alloc] initWithExercise:exercise repetitions:repetitions weight:weight intensity:intensity andConfidence:1];
}

@end

@implementation MRRest
- (instancetype)init:(const planned_rest &)rest {
    self = [super init];
    _duration = rest.duration;
    _hrBelow = rest.heart_rate;
    return self;
}
@end

@implementation MRExercisePlanItem

- (instancetype)init:(const exercise_plan_item &)item {
    self = [super init];

    switch (item.tag) {
        case muvr::exercise_plan_item::rest:
            _rest = [[MRRest alloc] init:item.rest_item];
            break;
        case muvr::exercise_plan_item::exercise:
            switch (item.exercise_item.tag) {
                case muvr::planned_exercise::resistance:
                    _resistanceExercise = [MRResistanceExercise plannedExercise:item.exercise_item];
                default:
                    @throw @"Match error";
            }
    }
    
    return self;
}

@end

@implementation MRExercisePlanDeviation

- (instancetype)init:(const exercise_plan_deviation &)deviation {
    self = [super init];
    
    _actual = [[MRExercisePlanItem alloc] init:deviation.actual];
    _planned = [[MRExercisePlanItem alloc] init:deviation.planned];
    
    return self;
}

@end

@implementation MRExercisePlan {
    std::unique_ptr<exercise_plan> exercisePlan;
    NSArray *empty;
}

+ (instancetype)planWithResistanceExercises:(NSArray *)resistanceExercises andDefaultDuration:(uint)duration {
    return [[MRExercisePlan alloc] initWithResistanceExercises:resistanceExercises andDefaultRestDuration:duration];
}

+ (instancetype)adHoc {
    return [[MRExercisePlan alloc] init];
}

- (planned_exercise)fromMRResistanceExercise:(MRResistanceExercise *)exercise {
    double intensity = exercise.intensity != nil ? exercise.intensity.doubleValue : 0;
    double weight = exercise.weight != nil ? exercise.weight.doubleValue : 0;
    uint repetitions = exercise.repetitions != nil ? exercise.repetitions.intValue : 0;
    return planned_exercise(std::string(exercise.exercise.UTF8String), intensity, weight, repetitions);
}

- (instancetype)init {
    self = [super init];
    empty = [[NSArray alloc] init];
    return self;
}

- (instancetype)initWithResistanceExercises:(NSArray *)resistanceExercises andDefaultRestDuration:(uint)duration {
    self = [super init];
    
    std::vector<exercise_plan_item> plan;
    for (MRResistanceExercise *exercise : resistanceExercises) {
        planned_rest plannedRest {.duration = duration, .heart_rate = 0};
        plan.push_back([self fromMRResistanceExercise:exercise]);
        plan.push_back(plannedRest);
    }
    
    exercisePlan = std::unique_ptr<exercise_plan>(new simple_exercise_plan(plan));
    
    return self;
}

- (NSArray *)convert:(const std::vector<exercise_plan_item> &)items {
    NSMutableArray* result = [[NSMutableArray alloc] init];
    for (const auto &x : items) {
        [result addObject:[[MRExercisePlanItem alloc] init:x]];
    }
    return result;
}

- (NSArray *)exercise:(MRResistanceExercise *)actual {
    if (!exercisePlan) return empty;
    planned_exercise pe = [self fromMRResistanceExercise:actual];
    return [self convert:exercisePlan->exercise(pe, 0)];
}

- (NSArray *)rest {
    if (!exercisePlan) return empty;
    return [self convert:exercisePlan->no_exercise(0)];
}

- (NSArray *)completed {
    if (!exercisePlan) return empty;
    return [self convert:exercisePlan->completed()];
}

- (NSArray *)todo {
    if (!exercisePlan) return empty;
    return [self convert:exercisePlan->todo()];
}

- (NSArray *)deviations {
    if (!exercisePlan) return empty;
    NSMutableArray* result = [[NSMutableArray alloc] init];
    for (const auto &x : exercisePlan->deviations()) {
        [result addObject:[[MRExercisePlanDeviation alloc] init:x]];
    }
    return result;
}

- (double)progress {
    if (!exercisePlan) return 0;
    return exercisePlan->progress();
}

@end
