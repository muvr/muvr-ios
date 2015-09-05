#ifndef Muvr_MRModelParameters_h
#define Muvr_MRModelParameters_h

///
/// The model details
///
@interface MRModelParameters : NSObject

- (instancetype)initWithWeights:(NSData *)weights andLabels:(NSArray *)labels;

@property (readonly) NSData* weights;
@property (readonly) NSArray* labels;

@end

#endif
