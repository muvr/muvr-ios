#import "MRPreclassification.h"
#import "MuvrPreclassification/include/sensor_data.h"

using namespace muvr;

#pragma MARK - Temporary implementation of sensor_data_fuser

typedef std::function<void()> exercise_block_started_t;
typedef std::function<void(const std::vector<fused_sensor_data>&, const fusion_stats &)> exercise_block_ended_t;

class delegating_sensor_data_fuser : public sensor_data_fuser {
private:
    exercise_block_started_t m_exercise_block_started;
    exercise_block_ended_t m_exercise_block_ended;
public:
    delegating_sensor_data_fuser(exercise_block_started_t exercise_block_started,
                                 exercise_block_ended_t exercise_block_ended);
    
    virtual void exercise_block_ended(const std::vector<fused_sensor_data> &data, const fusion_stats &fusion_stats);
    
    virtual void exercise_block_started();
};

delegating_sensor_data_fuser::delegating_sensor_data_fuser(exercise_block_started_t exercise_block_started,
                                                           exercise_block_ended_t exercise_block_ended):
    m_exercise_block_ended(exercise_block_ended),
    m_exercise_block_started(exercise_block_started) {
    
}

void delegating_sensor_data_fuser::exercise_block_ended(const std::vector<fused_sensor_data> &data, const fusion_stats &fusion_stats) {
    m_exercise_block_ended(data, fusion_stats);
}

void delegating_sensor_data_fuser::exercise_block_started() {
    m_exercise_block_started();
}

#pragma MARK - MRPreclassification implementation

@implementation MRPreclassification {
    std::unique_ptr<sensor_data_fuser> m_fuser;
    //std::unique_ptr<sax_xxx> m_sax;
}

- (instancetype)init {
    self = [super init];
    auto started = [self]() {
        if (self.exerciseBlockDelegate != nil) [self.exerciseBlockDelegate exerciseBlockStarted];
    };
    auto ended = [self](const std::vector<fused_sensor_data> &data, const fusion_stats &fusion_stats) {
        if (self.exerciseBlockDelegate != nil) [self.exerciseBlockDelegate exerciseBlockEnded];
        // ***
        // step 1
        // step 2
        // ...
        // step n
        // ultimately classificationSucceeded, classificationAmbiguous, classificationFailed,
    };
    m_fuser = std::unique_ptr<sensor_data_fuser>(new delegating_sensor_data_fuser(started, ended));
    return self;
}

- (void)pushBack:(NSData *)data from:(int)location at:(CFAbsoluteTime)time {
    const uint8_t *buf = reinterpret_cast<const uint8_t*>(data.bytes);
    m_fuser->push_back(buf, sensor_location::wrist, (sensor_time_t)time * 1000);
}

@end
