#import "MRPreclassification.h"
#import "MuvrPreclassification/include/easylogging++.h"
#import "MuvrPreclassification/include/sensor_data.h"
#import "MuvrPreclassification/include/device_data_decoder.h"
#import "MuvrPreclassification/include/svm_classifier.h"
#import "MuvrPreclassification/include/svm_classifier_factory.h"
#import "MuvrPreclassification/include/classifier_loader.h"
#import "MuvrPreclassification/include/export.h"
#import "MuvrPreclassification/include/ensemble_classifier.h"
#import "MRMultilayerPerceptron.h"

using namespace muvr;

//#define WITH_CLASSIFICATION

INITIALIZE_EASYLOGGINGPP;

@implementation MRClassifiedResistanceExercise (x)

- (instancetype)initWithClassifiedExercise:(muvr::svm_classifier::classified_exercise&)classifiedExercise {
    NSString *x = [NSString stringWithCString:classifiedExercise.exercise_name().c_str() encoding:[NSString defaultCStringEncoding]];
    self = [self initWithResistanceExercise:[[MRResistanceExercise alloc] initWithId:x]
                                repetitions:@(classifiedExercise.repetitions())
                                     weight:@(classifiedExercise.weight())
                                  intensity:@(classifiedExercise.intensity())
                              andConfidence:classifiedExercise.confidence()];
    return self;
}

@end

class const_exercise_decider : public exercise_decider {
public:
    virtual exercise_result has_exercise(const raw_sensor_data& source, state &context) override {
        return yes;
    }
};

class const_movement_decider : public movement_decider {
public:
    virtual movement_result has_movement(const raw_sensor_data& source) const override {
        return yes;
    }
};

class monitoring_exercise_decider : public exercise_decider {
private:
    state m_last_state;
public:
    virtual exercise_result has_exercise(const raw_sensor_data& source, state &context) override {
        const auto r = exercise_decider::has_exercise(source, context);
        m_last_state = context;
        return r;
    }
    
    state last_state() const { return m_last_state; }
};

#pragma MARK - Threed implementation

@implementation Threed
@end

@implementation MRPreclassification {
    std::shared_ptr<movement_decider> movementDecider;
    std::shared_ptr<exercise_decider> exerciseDecider;
    
    std::unique_ptr<sensor_data_fuser> fuser;
    
    MRResistanceExercise *trainingExercise;
    
    MRMultilayerPerceptron * classifier;
}

+ (instancetype)training {
    return [[MRPreclassification alloc] initWithModel:nil];
}

+ (instancetype)classifying:(MRModelParameters *)model {
    return [[MRPreclassification alloc] initWithModel:model];
}

- (instancetype)initWithModel:(MRModelParameters *)model {
    self = [super init];
    movementDecider = std::shared_ptr<movement_decider>(new const_movement_decider);
    exerciseDecider = std::shared_ptr<exercise_decider>(new const_exercise_decider);
    fuser = std::unique_ptr<sensor_data_fuser>(new sensor_data_fuser(movementDecider, exerciseDecider));
    
    classifier = [[MRMultilayerPerceptron alloc] initWithModel:model];
    return self;
}

- (NSData *)formatFusedSensorData:(sensor_data_fuser::fusion_result&)fusionResult {
    std::ostringstream os;
    os << "[";
    for (int i = 0; i < fusionResult.fused_exercise_data().size(); ++i) {
        if (i > 0) os << ",";
        export_data(os, fusionResult.fused_exercise_data()[i]);
    }
    os << "]";
    
    return [[NSString stringWithUTF8String:os.str().c_str()] dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)pushBack:(NSData *)data from:(uint8_t)location withHint:(MRResistanceExercise *)plannedExercise {
    try {
        const uint8_t *buf = reinterpret_cast<const uint8_t*>(data.bytes);
        raw_sensor_data decoded = decode_single_packet(buf).first;
        // A: std::optional<fused_sensor_data> res = fuser->push_back(decoded, loc, 0, min_window = 4000); mutating
        
        // B: fuser->push_back(decoded, loc, 0) mutating;
        //    fuser->window(from_end = 4000);
        //    fuser->slice(from, to);
        // ---
        //   fuser->erase_before()
        
        sensor_data_fuser::fusion_result fusionResult = fuser->push_back(decoded, sensor_location_t::wrist, 0);

        // hooks & delegates
        
        // first, handle the device data stuff
        if (self.deviceDataDelegate != nil) {
            Mat data = decoded.data();
            
            NSMutableArray *values = [[NSMutableArray alloc] init];
            for (int i = 0; i < data.rows; ++i) {
                if (data.cols == 3) {
                    Threed *t = [[Threed alloc] init];
                    t.x = data.at<int16_t>(i, 0);
                    t.y = data.at<int16_t>(i, 1);
                    t.z = data.at<int16_t>(i, 2);
                    [values addObject:t];
                } else if (data.cols == 1) {
                    [values addObject:[NSNumber numberWithInt:data.at<int16_t>(i, 0)]];
                } else {
                    throw std::runtime_error("unreportable data dimension");
                }
            }
            [self.deviceDataDelegate deviceDataDecoded3D:values fromSensor:decoded.type() device:decoded.device_id() andLocation:location];
        }

        // second, the exercise blocks
        if (self.exerciseBlockDelegate != nil) {
            switch (fusionResult.type()) {
                case sensor_data_fuser::fusion_result::not_moving:
                    [self.exerciseBlockDelegate notMoving];
                    break;
                case sensor_data_fuser::fusion_result::moving:
                    [self.exerciseBlockDelegate moving];
                    break;
                case sensor_data_fuser::fusion_result::exercising:
                    [self.exerciseBlockDelegate exercising];
                    break;
                case sensor_data_fuser::fusion_result::exercise_ended:
                    [self.exerciseBlockDelegate exerciseEnded];
                    break;
            }
        }
        
        // TODO: Put classification right here using windows of fused data
    } catch (std::exception &ex) {
        std::cerr << ex.what() << std::endl;
    } catch (...) {
        std::cerr << "Something is fucked up" << std::endl;
    }
}

- (void)exerciseCompleted {
    if (self.classificationPipelineDelegate == nil) return;
    assert(trainingExercise == nil); // "trainingExercise == nil failed. [trainingStarted:] not caled.");
    
    auto result = fuser->completed();
    NSData *data = [self formatFusedSensorData:result];
    
    // --- Move classification to pushBack
    svm_classifier::classification_result classificationResult = [classifier classify:result.fused_exercise_data() withMaxResultsOf: 3];
    
    NSMutableArray *transformedClassificationResult = [NSMutableArray array];
    
    if (classificationResult.exercises().size() > 0) {
        // for now we just take the first and only identified exercise if there is any
        std::vector<muvr::svm_classifier::classified_exercise> exercises = classificationResult.exercises();
        for (size_t i=0; i < exercises.size(); i++){
            MRClassifiedResistanceExercise *exercise = [[MRClassifiedResistanceExercise alloc] initWithClassifiedExercise:exercises[i]];
            [transformedClassificationResult addObject:exercise];
        }
    }
    
    [self.classificationPipelineDelegate classificationCompleted:transformedClassificationResult fromData:data];
}

- (void)trainingCompleted {
    if (self.trainingPipelineDelegate == nil) return;
    assert(trainingExercise != nil); // "trainingExercise != nil failed. [trainingStarted:] not caled.");
    
    auto result = fuser->completed();
    NSData *data = [self formatFusedSensorData:result];
    
    // --- End classification
    [self.trainingPipelineDelegate trainingCompleted:trainingExercise fromData:data];
    trainingExercise = nil;
}

- (void)trainingStarted:(MRResistanceExercise *)exercise {
    fuser->clear();
    trainingExercise = exercise;
}

@end
