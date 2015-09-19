#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <HealthKit/HealthKit.h>

@interface MRMutableSensorData : NSObject

- (void)append:(CMDeviceMotion *)data;

@end
