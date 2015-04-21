#import "MRPreclassification.h"
#import "MuvrPreclassification/include/easylogging++.h"
#import "MuvrPreclassification/include/sensor_data.h"
#import "MuvrPreclassification/include/classifier.h"

using namespace muvr;

INITIALIZE_EASYLOGGINGPP;

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

#pragma MARK - Temporary implementation of classifier

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
    auto started = [self]() {
        if (self.exerciseBlockDelegate != nil) [self.exerciseBlockDelegate exerciseBlockStarted];
    };
    auto ended = [self](const std::vector<fused_sensor_data> &data, const fusion_stats &fusion_stats) {
        if (self.exerciseBlockDelegate != nil) [self.exerciseBlockDelegate exerciseBlockEnded];
        
        // all preprocessing + classification steps happen in the classify method.
        // so we are able to use a whole different pipeline
        // ultimately classificationSucceeded, classificationAmbiguous, classificationFailed,
        m_classifier->classify(data[0]);
    };
    auto success = [self](const std::string &exercise, const fused_sensor_data &fromData) {
        if (self.classificationPipelineDelegate != nil) [self.classificationPipelineDelegate classificationSucceeded];
    };
    auto ambiguous = [self](const std::vector<std::string> &exercises, const fused_sensor_data &fromData) {
        if (self.classificationPipelineDelegate != nil) [self.classificationPipelineDelegate classificationAmbiguous];
    };
    auto failed = [self](const fused_sensor_data &fromData) {
        if (self.classificationPipelineDelegate != nil) [self.classificationPipelineDelegate classificationFailed];
    };
    
    m_fuser = std::unique_ptr<sensor_data_fuser>(new delegating_sensor_data_fuser(started, ended));
    m_classifier = std::unique_ptr<classifier>(new delegating_classifier(success, ambiguous, failed));
    
    return self;
}

- (void)pushBack:(NSData *)data from:(int)location at:(CFAbsoluteTime)time {
    const uint8_t *buf = reinterpret_cast<const uint8_t*>(data.bytes);
    m_fuser->push_back(buf, sensor_location::wrist, 0);
}

@end
