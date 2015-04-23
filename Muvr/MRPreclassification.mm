#import "MRPreclassification.h"
#import "MuvrPreclassification/include/easylogging++.h"
#import "MuvrPreclassification/include/sensor_data.h"
#import "MuvrPreclassification/include/device_data_decoder.h"
#import "MuvrPreclassification/include/classifier.h"

using namespace muvr;

INITIALIZE_EASYLOGGINGPP;

class const_exercise_decider : public exercise_decider {
public:
    virtual exercise_result has_exercise(const raw_sensor_data& source, exercise_context &context) const {
        return yes;
    }
};

typedef std::function<void(const std::string&, const fused_sensor_data&)> classification_succeeded_t;
typedef std::function<void(const std::vector<std::string>&, const fused_sensor_data&)> classification_ambiguous_t;
typedef std::function<void(const fused_sensor_data&)> classification_failed_t;

class delegating_classifier : public classifier {
private:
    classification_succeeded_t m_classification_succeeded;
    classification_ambiguous_t m_classification_ambiguous;
    classification_failed_t m_classification_failed;
public:
    delegating_classifier(classification_succeeded_t classification_succeeded,
                          classification_ambiguous_t classification_ambiguous,
                          classification_failed_t classification_failed);
    
    virtual void classification_succeeded(const std::string &exercise, const fused_sensor_data &fromData);
    
    virtual void classification_ambiguous(const std::vector<std::string> &exercises, const fused_sensor_data &fromData);
    
    virtual void classification_failed(const fused_sensor_data &fromData);
};

delegating_classifier::delegating_classifier(classification_succeeded_t classification_succeeded,
                                             classification_ambiguous_t classification_ambiguous,
                                             classification_failed_t classification_failed):
m_classification_succeeded(classification_succeeded),
m_classification_ambiguous(classification_ambiguous),
m_classification_failed(classification_failed) {
}

void delegating_classifier::classification_succeeded(const std::string &exercise, const fused_sensor_data &fromData) {
    m_classification_succeeded(exercise, fromData);
}

void delegating_classifier::classification_ambiguous(const std::vector<std::string> &exercises, const fused_sensor_data &fromData) {
    m_classification_ambiguous(exercises, fromData);
}

void delegating_classifier::classification_failed(const fused_sensor_data &fromData) {
    m_classification_failed(fromData);
}

#pragma MARK - MRPreclassification implementation

@implementation MRPreclassification {
    std::unique_ptr<sensor_data_fuser> m_fuser;
    std::unique_ptr<classifier> m_classifier;
}

- (instancetype)init {
    self = [super init];
    auto success = [self](const std::string &exercise, const fused_sensor_data &fromData) {
        if (self.classificationPipelineDelegate != nil) [self.classificationPipelineDelegate classificationSucceeded];
    };
    auto ambiguous = [self](const std::vector<std::string> &exercises, const fused_sensor_data &fromData) {
        if (self.classificationPipelineDelegate != nil) [self.classificationPipelineDelegate classificationAmbiguous];
    };
    auto failed = [self](const fused_sensor_data &fromData) {
        if (self.classificationPipelineDelegate != nil) [self.classificationPipelineDelegate classificationFailed];
    };
    
    m_fuser = std::unique_ptr<sensor_data_fuser>(new sensor_data_fuser(std::shared_ptr<movement_decider>(new movement_decider()),
                                                                       std::shared_ptr<exercise_decider>(new const_exercise_decider())));
    m_classifier = std::unique_ptr<classifier>(new delegating_classifier(success, ambiguous, failed));
    
    return self;
}

- (void)pushBack:(NSData *)data from:(int)location at:(CFAbsoluteTime)time {
    const uint8_t *buf = reinterpret_cast<const uint8_t*>(data.bytes);
    raw_sensor_data decoded = decode_single_packet(buf);
    if (self.deviceDataDelegate != nil) {
        Mat data = decoded.data();
        
        //uint16_t **memory = data.ptr<uint16_t*>();
        //[self.deviceDataDelegate deviceDataDecoded:memory rows:data.rows cols:data.cols];

        NSMutableArray *values = [[NSMutableArray alloc] init];
        for (int i = 0; i < data.cols; ++i) {
            NSMutableArray *value = [[NSMutableArray alloc] init];
            for (int j = 0; j < data.rows; ++j) {
                NSNumber *n = [NSNumber numberWithInt:data.at<int16_t>(j, i)];
                [value addObject:n];
            }
            [values addObject:value];
        }
        [self.deviceDataDelegate deviceDataDecoded:values];
    }
    sensor_data_fuser::fusion_result result = m_fuser->push_back(decoded, sensor_location_t::wrist, 0);
    switch (result.type()) {
        case sensor_data_fuser::fusion_result::not_moving:
            if (self.exerciseBlockDelegate != nil) [self.exerciseBlockDelegate notMoving];
            break;
        case sensor_data_fuser::fusion_result::moving:
            if (self.exerciseBlockDelegate != nil) [self.exerciseBlockDelegate moving];
            break;
        case sensor_data_fuser::fusion_result::exercising:
            if (self.exerciseBlockDelegate != nil) [self.exerciseBlockDelegate exercising];
            break;
        case sensor_data_fuser::fusion_result::exercise_ended:
            if (self.exerciseBlockDelegate != nil) [self.exerciseBlockDelegate exerciseEnded];
            break;
    }
}

@end
