#import <Foundation/Foundation.h>
#import "MRMultilayerPerceptron.h"
#import "MuvrPreclassification/include/sensor_data.h"
#include "easylogging++.h"
#import "MLPNeuralNet.h"

#pragma MARK - MRResistanceExerciseSet implementation

@implementation MRMultilayerPerceptron{
    // Size of the moving window over the data. Specific to the trained model
    int _windowSize;
    // Number of classes the model got trained on
    int _nrOfClasses;
    // Label mapping of ids to human strings. Labels need to be sorted asc by id. Model specific
    NSArray *_labels;
    // Trained MLP model
    MLPNeuralNet * _model;
}

// Load label mapping from bundle
- (void)loadLabelsFromBundle: (NSString *)bundlePath {
    
    NSString *labelsFile = [[NSBundle bundleWithPath:bundlePath] pathForResource: @"labels" ofType: @"txt"];
    NSString *labelsContent = [NSString stringWithContentsOfFile:labelsFile encoding:NSUTF8StringEncoding error:nil];
    
    _labels = [labelsContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

// Load Model from bundle
- (void)loadModelFromBundle: (NSString *)bundlePath {
    
    // Load weights from file. The file is a raw file containing an array of double values
    NSString* path = [[NSBundle bundleWithPath:bundlePath] pathForResource: @"weights" ofType: @"raw"];
    
    NSData *weights = [NSData dataWithContentsOfFile:path];
    
    // TODO: Load model from file and set attributes
    NSArray *layers = [NSArray arrayWithObjects:@1200, @500, @250, @100, @29, nil];
    
    // Lets assume we loaded the data correctly
    // assert(weights.length / 8 == 370279);
    
    _model = [[MLPNeuralNet alloc] initWithLayerConfig:layers
                                               weights:weights
                                            outputMode:MLPClassification];
    _model.hiddenActivationFunction = MLPReLU;
    _model.outputActivationFunction = MLPSigmoid;
}

- (instancetype)initFromFiles: (NSString *)bundlePath {
    self = [super init];
    
    //TODO: Move parameters to file loaded from generated model
    _windowSize = 400;
    _nrOfClasses = 29;
    
    // Default settings
    [self setWindowStepSize: 10];
    
    
    [self loadLabelsFromBundle: bundlePath];
    
    [self loadModelFromBundle: bundlePath];
    
    return self;
}

// Make sure the matrix has the correct datatype
- (cv::Mat)initial_preprocessing: (const cv::Mat &)data {
    Mat cv_data;
    // Convert to double precision
    data.convertTo(cv_data, CV_64FC1);
    
    return cv_data;
}

// Center and scale the given data
- (cv::Mat)transform_scale: (const cv::Mat &)data withScale:(double)scale withCenter:(double)center{
    Mat scaled_data = data.clone();
    
    for (int j = 0; j < data.cols; j++) {
        double val = scaled_data.at<double>(0, j);
        scaled_data.at<double>(0, j) = (val - center) / scale;
    }
    
    return scaled_data;
}

// Prepare data for classification
- (cv::Mat)preprocessingPipeline: (const cv::Mat &)data withScale:(double)scale withCenter:(double)center {
    // Flatten matrix using column-major transformation.
    Mat feature_vector =  Mat(data.t()).reshape(1, 1);
    
    Mat scaled_feature_vector = [self transform_scale: feature_vector withScale: scale withCenter: center];
    
    return scaled_feature_vector;
}
// Map a classifier output to a label
- (NSString *)exerciseName: (int) idx{
    return [_labels objectAtIndex: idx];
}

// Convert Mat into a NSData column first vector
- (NSMutableData*) dataFromMat:(cv::Mat*) image
{
    int matRows = image->rows;
    int matCols = image->cols;
    NSMutableData* data = [[NSMutableData alloc]init];
    double *pix;
    for (int i = 0; i < matRows; Ïi++)
    {
        for (int j = 0; j < matCols; j++ )
        {
            pix = &image->at<double>(i, j);
            [data appendBytes:(void*)pix length: sizeof(double)];
        }
    }
    return data;
}

-  (svm_classifier::classification_result)classify: (const std::vector<fused_sensor_data> &)data{

    if(data.size() == 0){
        LOG(WARNING) << "Classification called, but no data passed!" << std::endl;
        return svm_classifier::classification_result(muvr::svm_classifier::classification_result::failure, std::vector<muvr::svm_classifier::classified_exercise> { }, data);
    }
    
    auto first_sensor_data = data[0];
    
    // Apply initial preprocessing steps to data.
    Mat preprocessed = [self initial_preprocessing:first_sensor_data.data];
    
    // LOG(TRACE) << "Raw input data = "<< std::endl << " "  << preprocessed << std::endl << std::endl;
    
    // Sliding window.
    int numWindows = 0;
    int prediction = -1;
    double overall_prediction[_nrOfClasses];
    
    for(int c=0; c < _nrOfClasses; ++c){
        overall_prediction[c] = 0;
    }
    
    // We need a window full of data to do any prediction
    if(first_sensor_data.data.rows < _windowSize){
        LOG(INFO) << "Not enough data for prediction :( " << std::endl;
    }

    for(int i = 0; i + _windowSize <= first_sensor_data.data.rows; i += [self windowStepSize]) {
        // Get window expected size.
        Mat window = preprocessed(cv::Range(i, i + _windowSize), cv::Range(0, 3));
        Mat feature_matrix = [self preprocessingPipeline:window withScale:4000 withCenter:0];
        
        // Predict output of the model for new sample
        NSMutableData * windowPrediction = [NSMutableData dataWithLength:sizeof(double)*_nrOfClasses];
        NSData *feature_vector = [self dataFromMat: &feature_matrix];
        
        // Run the model on the feature vector. We will get a vector of probabilities for the different classes
        [_model predictByFeatureVector:feature_vector intoPredictionVector:windowPrediction];
        double * confidenceScores = (double *)windowPrediction.bytes;
        
        // For now we will select the class that is most probable over all windows. More advanced selection possible
        for(int c=0; c < _nrOfClasses; ++c){
//            NSString * exerciseName = [self exerciseName: c];
//            LOG(TRACE) << "Prediction: "<< [NSString stringWithFormat:@"%.2f", confidenceScores[c]].UTF8String <<" for " << exerciseName.UTF8String << std::endl;
            overall_prediction[c] += confidenceScores[c];
            if(prediction == -1 or overall_prediction[prediction] < overall_prediction[c])  {
                prediction = c;
            }
        }
        numWindows++;
    }

    if(prediction >= 0) {
        for(int c=0; c < _nrOfClasses; ++c){
            NSString * exerciseName = [self exerciseName: c];
            LOG(TRACE) << "Prediction: "<< [NSString stringWithFormat:@"%.2f", overall_prediction[c]].UTF8String <<" for " << exerciseName.UTF8String << std::endl;
        }
        
        NSString * exerciseName = [self exerciseName: prediction];
        LOG(DEBUG) << "Final Prediction: "<< [NSString stringWithFormat:@"%.2f", overall_prediction[prediction] / numWindows].UTF8String <<" for " << exerciseName.UTF8String << std::endl;
        
        muvr::svm_classifier::classified_exercise exercise = svm_classifier::classified_exercise(exerciseName.UTF8String, -1, 1.0, 1.0, overall_prediction[prediction] / numWindows);
        return svm_classifier::classification_result(muvr::svm_classifier::classification_result::success, std::vector<muvr::svm_classifier::classified_exercise> { exercise }, data);
    } else {
        LOG(INFO) << "NO PREDICTION!" << std::endl;
        return svm_classifier::classification_result(muvr::svm_classifier::classification_result::failure, std::vector<muvr::svm_classifier::classified_exercise> { }, data);
    }
}

@end