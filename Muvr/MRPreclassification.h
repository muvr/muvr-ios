#import <Foundation/Foundation.h>

@protocol MRExerciseBlockDelegate
- (void)exerciseBlockStarted;
- (void)exerciseBlockEnded;
@end

@interface MRPreclassification : NSObject
- (instancetype)init;
- (void)pushBack:(NSData *)data from:(int)location at:(CFAbsoluteTime)time;

@property id<MRExerciseBlockDelegate> exerciseBlockDelegate;
@end
