#import <Foundation/Foundation.h>
#import "MRModelParameters.h"

@implementation MRModelParameters

- (instancetype)initWithWeights:(NSData *)weights andLabels:(NSArray *)labels {
    self = [super init];
    
    _weights = weights;
    _labels = labels;
    
    return self;
}

@end
