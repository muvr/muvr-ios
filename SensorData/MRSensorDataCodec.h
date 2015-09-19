#import <Foundation/Foundation.h>
#import "MRSensorData.h"

MRSensorData* decode(NSData* buffer);

NSData* encode(MRSensorData* data);
