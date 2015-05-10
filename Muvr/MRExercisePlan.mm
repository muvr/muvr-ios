#import <Foundation/Foundation.h>
#import "MRExercisePlan.h"
#import "MuvrPreclassification/include/exercise_plan.h"

using namespace muvr;

@implementation MRExercisePlan {
    std::unique_ptr<exercise_plan> exercisePlan;
}

- (planned_exercise)fromMRResistanceExercise:(MRResistanceExercise *)exercise {
    double intensity = exercise.intensity != nil ? exercise.intensity.doubleValue : 0;
    double weight = exercise.weight != nil ? exercise.weight.doubleValue : 0;
    uint repetitions = exercise.repetitions != nil ? exercise.repetitions.intValue : 0;
    return planned_exercise(std::string(exercise.exercise.UTF8String), intensity, weight, repetitions);
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

- (NSArray *)exercise:(MRResistanceExercise *)actual {
    planned_exercise pe = [self fromMRResistanceExercise:actual];
    exercisePlan->exercise(pe, 0);
    
    return NULL;
}

- (NSArray *)rest {
    exercisePlan->no_exercise(0);
    
    return NULL;
}

@end