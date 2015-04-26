#import "MRPreclassification.h"
#import "MuvrPreclassification/include/easylogging++.h"
#import "MuvrPreclassification/include/sensor_data.h"
#import "MuvrPreclassification/include/device_data_decoder.h"
#import "MuvrPreclassification/include/svm_classifier.h"
#import "MuvrPreclassification/include/svm_classifier_factory.h"

using namespace muvr;

INITIALIZE_EASYLOGGINGPP;

class const_exercise_decider : public exercise_decider {
public:
    virtual exercise_result has_exercise(const raw_sensor_data& source, exercise_context &context) const {
        return yes;
    }
};

@implementation Threed
@end

@implementation MRPreclassification {
    std::unique_ptr<sensor_data_fuser> m_fuser;
    std::unique_ptr<svm_classifier> m_classifier;
}

- (instancetype)init {
    self = [super init];
    
    m_fuser = std::unique_ptr<sensor_data_fuser>(new sensor_data_fuser(std::shared_ptr<movement_decider>(new movement_decider()),
                                                                       std::shared_ptr<exercise_decider>(new const_exercise_decider())));
    
    NSString *fullPath = [[NSBundle mainBundle] pathForResource:@"svm-model-curl-features" ofType:@"libsvm"];
    std::string libsvm(fullPath.UTF8String);
    fullPath = [[NSBundle mainBundle] pathForResource:@"svm-model-curl-features" ofType:@"scale"];
    std::string scale(fullPath.UTF8String);
    
    auto classifier = svm_classifier_factory().build(libsvm, scale);
    m_classifier = std::unique_ptr<svm_classifier>(&classifier);
    
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
        for (int i = 0; i < data.rows; ++i) {
            if (data.cols == 3) {
                Threed *t = [[Threed alloc] init];
                t.x = data.at<int16_t>(i, 0);
                t.y = data.at<int16_t>(i, 1);
                t.z = data.at<int16_t>(i, 2);
                [values addObject:t];
            }
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
            
            svm_classifier::classification_result classification_result = m_classifier->classify(result.fused_exercise_data());
            
            switch (classification_result.type()) {
                case svm_classifier::classification_result::success:{
                    NSString* exercise = [NSString stringWithCString:classification_result.exercises()[0].c_str()encoding:[NSString defaultCStringEncoding]];
                    
                    if (self.classificationPipelineDelegate != nil)
                        [self.classificationPipelineDelegate classificationSucceeded:exercise reps:classification_result.repetitions()];
                    break;
                }
                case svm_classifier::classification_result::ambiguous: {
                    if (self.classificationPipelineDelegate != nil) [self.classificationPipelineDelegate classificationAmbiguous];
                    break;
                }
                case svm_classifier::classification_result::failure: {
                    if (self.classificationPipelineDelegate != nil) [self.classificationPipelineDelegate classificationFailed];
                    break;
                }
            }
            
            break;
    }
}

@end
