#import "Preclassification.h"
#import "MuvrPreclassification/include/device_data_decoder.h"

@implementation Preclassification

using namespace muvr;

+ (void)pushBack:(NSData *)data atLocation:(int)location {
    const uint8_t *buf = reinterpret_cast<const uint8_t*>(data.bytes);
    decode_single_packet(buf);
}

@end
