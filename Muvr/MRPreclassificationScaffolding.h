#ifndef Muvr_MRPreclassificationScaffolding_h
#define Muvr_MRPreclassificationScaffolding_h

#import <Foundation/Foundation.h>

/// The 3D axis
enum MR3DAxis {
    x, y, z
};

///
/// Input data for a periodogram: powers for the given frequency.
///
@interface MRFreqPower : NSObject
@property (readonly) double frequency;
@property (readonly) double power;
@end

///
/// The state of the exercise decider
///
@interface MRExerciseDeciderState : NSObject
/// the dominant axis
@property (readonly) MR3DAxis dominantAxis;
/// MRFreqPower* of the dominant axis
@property (readonly) MRFreqPower* freqPower;


/// velocity for the dominant axis
@property (readonly) double velocity;
/// the distance moved along the dominant axis
@property (readonly) double distance;
@end

#endif
