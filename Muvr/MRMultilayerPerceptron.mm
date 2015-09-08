#import <Foundation/Foundation.h>
#import "MRMultilayerPerceptron.h"
#import "MuvrPreclassification/include/sensor_data.h"
#include "easylogging++.h"
#import "MLPNeuralNet.h"
#import "MRClassifiedResistanceExercise.h"

#pragma MARK - MRResistanceExerciseSet implementation

@implementation MRMultilayerPerceptron {
    // Size of the moving window over the data. Specific to the trained model
    uint _windowSize;
    // Number of classes the model got trained on
    uint nrOfClasses;
    // Number of features the model got trained on
    uint nrOfFeatures;
    // Trained MLP model
    MLPNeuralNet *model;
    // The human-readable labels
    NSArray *labels;
}

- (instancetype)initWithModel:(MRModelParameters *)modelParamters {
    self = [super init];
    labels = modelParamters.labels;

    //TODO: Move parameters to file loaded from generated model
    _windowSize = 400;
    nrOfFeatures = 1200;
    nrOfClasses = uint(labels.count);
    
    assert(nrOfClasses > 0); // There should be at least one class for classification.
    
    // TODO: Load model from file and set attributes
    NSArray *layers = [NSArray arrayWithObjects:@1200, @100, @50, @3, nil];
    
    // Lets assume we loaded the data correctly
    // assert(weights.length / 8 == 370279);
    model = [[MLPNeuralNet alloc] initWithLayerConfig:layers
                                               weights:modelParamters.weights
                                            outputMode:MLPClassification];
    model.hiddenActivationFunction = MLPReLU;
    model.outputActivationFunction = MLPSigmoid;
    
    // Default settings
    [self setWindowStepSize:10];
    
    return self;
}

// Make sure the matrix has the correct datatype
- (cv::Mat)initialPreprocessing:(const cv::Mat &)data {
    Mat cvData;
    // Convert to double precision
    data.convertTo(cvData, CV_64FC1);
    return cvData;
}

// Center and scale the given data
- (cv::Mat)transformScale:(const cv::Mat &)data withScale:(double)scale withCenter:(double)center{
    Mat scaledData = data.clone();
    
    for (int j = 0; j < data.cols; j++) {
        double val = scaledData.at<double>(0, j);
        scaledData.at<double>(0, j) = (val - center) / scale;
    }
    
    return scaledData;
}

// Prepare data for classification
- (cv::Mat)preprocessingPipeline:(const cv::Mat &)data withScale:(double)scale withCenter:(double)center {
    // Flatten matrix using column-major transformation.
    Mat featureVector =  Mat(data.t()).reshape(1, 1);
    Mat scaledFeatureVector = [self transformScale:featureVector withScale:scale withCenter:center];
    return scaledFeatureVector;
}

// Map a classifier output to a label
- (NSString *)exerciseName:(int)idx{
    return [labels objectAtIndex:idx];
}

// Convert Mat into a NSData column first vector
- (NSMutableData*)dataFromMat:(cv::Mat*)image
{
    int matRows = image->rows;
    int matCols = image->cols;
    NSMutableData* data = [[NSMutableData alloc] init];
    double *pix;
    for (int i = 0; i < matRows; i++) {
        for (int j = 0; j < matCols; j++ ) {
            pix = &image->at<double>(i, j);
            [data appendBytes:(void*)pix length:sizeof(double)];
        }
    }
    return data;
}

- (NSMutableArray *)calculateClassProbabilities:(double *)predictions withSize:(NSUInteger)numWindows{
    NSMutableArray *probabilities = [[NSMutableArray alloc] init];
    
    // Sum up the probabilities over the different predictions
    for (int i=0; i < nrOfClasses; ++i) {
        double sumForClass = 0.0;
        for (int w = 0; w < numWindows; ++w) {
            sumForClass += predictions[i * numWindows + w];
        }
        
        [probabilities addObject:[NSNumber numberWithDouble: sumForClass / numWindows]];
    }
    return probabilities;
}

- (NSMutableArray *)createRanking:(NSMutableArray *)probabilities {
    NSMutableArray *classRanking = [[NSMutableArray alloc] init];
    for (int i=0; i < nrOfClasses; ++i) {
        [classRanking addObject:[NSNumber numberWithInteger:i]];
    }
    
    [classRanking sortWithOptions:0 usingComparator:^NSComparisonResult(id obj1, id obj2) {
        // Modify this to use [probabilities objectAtIndex:[obj1 intValue]] property
        NSNumber *lhs = [probabilities objectAtIndex:[obj1 intValue]];
        // Same goes for the next line: use the name
        NSNumber *rhs = [probabilities objectAtIndex:[obj2 intValue]];
        // Sort in descending order
        return [rhs compare:lhs];
    }];
    
    return classRanking;
}

- (void)printClassificationResult:(NSMutableArray *)probabilities withRanking:(NSMutableArray *)class_ranking {
    [class_ranking enumerateObjectsUsingBlock:^(NSNumber* classId, NSUInteger idx, BOOL *stop) {
        NSNumber *prob = [probabilities objectAtIndex: classId.integerValue];
        NSString * exerciseName = [self exerciseName:classId.intValue];
        LOG(TRACE) << "Prediction: " << [NSString stringWithFormat:@"%.2f", prob.doubleValue].UTF8String <<  " for " << exerciseName.UTF8String << std::endl;
    }];
}

- (NSMutableData *)featureMatrixFrom:(Mat)inputData withNumWindows:(NSUInteger)numWindows {
    NSMutableData *featureMatrix = [NSMutableData dataWithLength:nrOfFeatures * numWindows * sizeof(double)];
    double *features = (double *)featureMatrix.mutableBytes;
    
    for (int i = 0; i < numWindows; ++i) {
        // Get window expected size.
        uint start = i * [self windowStepSize];
        uint end = i * [self windowStepSize] + _windowSize;
        Mat window = inputData(cv::Range(start, end), cv::Range(0, 3));
        Mat featureMat = [self preprocessingPipeline:window withScale:4000 withCenter:0];
        
        // Predict output of the model for new sample
        NSData *windowFeatures = [self dataFromMat:&featureMat];
        memcpy(&features[i*nrOfFeatures], (double *)windowFeatures.bytes, nrOfFeatures * sizeof(double));
    }
    
    return featureMatrix;
}

- (NSArray *)classify:(const std::vector<fused_sensor_data> &)data withMaximumResults:(uint)numberOfResults {
    NSDate *startTime = [NSDate date];
    if (data.size() == 0) {
        LOG(WARNING) << "Classification called, but no data passed!" << std::endl;
        return [[NSArray alloc] init];
    }
    
    auto firstSensorData = data[0];
    
    // We need a window full of data to do any prediction
    if (firstSensorData.data.rows < _windowSize) {
        LOG(INFO) << "Not enough data for prediction :( " << std::endl;
        return [[NSArray alloc] init];
    }
    
    // Apply initial preprocessing steps to data.
    Mat preprocessed = [self initialPreprocessing:firstSensorData.data];
    
    // Size of the sliding window
    NSUInteger numWindows = (firstSensorData.data.rows - _windowSize) / [self windowStepSize] + 1;
    NSMutableData *featureMatrix = [ self featureMatrixFrom: preprocessed withNumWindows: numWindows];
    NSMutableData *windowPrediction = [NSMutableData dataWithLength:nrOfClasses*numWindows*sizeof(double)];
    
    // Run the model on the feature vector. We will get a vector of probabilities for the different classes
    [model predictByFeatureMatrix:featureMatrix intoPredictionMatrix:windowPrediction];
    
    double *confidenceScores = (double *)windowPrediction.bytes;
    NSMutableArray *probabilities = [self calculateClassProbabilities:confidenceScores withSize:numWindows];
    NSMutableArray *classRanking = [self createRanking:probabilities];
    
    // Some debug logging to know what the classification is doing
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:startTime];
    LOG(TRACE) << "Classification took: " << timeInterval << " seconds for " << firstSensorData.data.rows / firstSensorData.samples_per_second << " seconds of data" << std::endl;
    
    [self printClassificationResult:probabilities withRanking:classRanking];
    
    int resultSize = std::min(numberOfResults, nrOfClasses);
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    for (int i=0; i < resultSize; ++i) {
        NSNumber *classId = [classRanking objectAtIndex:i];
        NSString *exerciseName = [self exerciseName:classId.intValue];
        NSNumber *prob = [probabilities objectAtIndex:classId.integerValue];

        MRResistanceExercise* re = [[MRResistanceExercise alloc] initWithId:exerciseName];
        MRClassifiedResistanceExercise *cre = [[MRClassifiedResistanceExercise alloc] initWithResistanceExercise:re
                                                                                                     repetitions:0
                                                                                                          weight:0
                                                                                                       intensity:0
                                                                                                   andConfidence:prob.doubleValue];
        [result addObject:cre];
    }
    
    return result;
}

@end
