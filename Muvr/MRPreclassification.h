#import <Foundation/Foundation.h>

///
/// The most coarse exercise detection
///
@protocol MRExerciseBlockDelegate

///
/// Movement detected consistent with some specific exercise.
///
- (void)exerciseBlockStarted;

///
/// The exercise block has ended: either because there is no movement, or the exercise
/// movement became too divergent.
///
- (void)exerciseBlockEnded;
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
- (void)pushBack:(NSData *)data from:(int)location at:(CFAbsoluteTime)time;

///
/// Sets the exercise block delegate, whose methods get called when entire exercise
/// block is detected.
///
@property id<MRExerciseBlockDelegate> exerciseBlockDelegate;
@end
