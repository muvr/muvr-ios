#import <Foundation/Foundation.h>
#import "MRMultilayerPerceptron.h"
#import "MuvrPreclassification/include/sensor_data.h"
#include "easylogging++.h"
#import "MLPNeuralNet.h"

#pragma MARK - MRResistanceExerciseSet implementation

using namespace muvr;

@implementation MRMultilayerPerceptron{
    int _windowSize;
    int _stepSize;
    int _nrOfClasses;
    NSArray *_labels;
    MLPNeuralNet * _model;
}

- (instancetype)initFromFiles: (NSString *)bundlePath {
    self = [super init];
    
    //TODO: Parameters
    _windowSize = 400;
    _stepSize = 10;
    _nrOfClasses = 29;
    
    // Load label mapping
    NSString *labelsFile = [[NSBundle bundleWithPath:bundlePath] pathForResource: @"labels" ofType: @"txt"];
    NSString *labelsContent = [NSString stringWithContentsOfFile:labelsFile encoding:NSUTF8StringEncoding error:nil];
    
    _labels = [labelsContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    
    // Load weights from file. The file is a raw file containing an array of double values
    NSString* path = [[NSBundle bundleWithPath:bundlePath] pathForResource: @"weights" ofType: @"raw"];
    
    NSData *weights = [NSData dataWithContentsOfFile:path];
    
    // TODO: Load model from file and set attributes
    NSArray *layers = [NSArray arrayWithObjects:@1200, @500, @250, @100, _nrOfClasses, nil];
    
    // Lets assume we loaded the data correctly
    assert(weights.length / 8 == 753779);
    
    _model = [[MLPNeuralNet alloc] initWithLayerConfig:layers
                                                            weights:weights
                                                         outputMode:MLPClassification];
    _model.activationFunction = MLPReLU;
    
    return self;
}

- (cv::Mat)initial_preprocessing: (const cv::Mat &)data {
    Mat cv_data;
    data.convertTo(cv_data, CV_64FC1);
    
    return cv_data;
}

- (cv::Mat)transform_scale: (const cv::Mat &)data withScale:(double)scale withCenter:(double)center{
    Mat scaled_data = data.clone();
    
    for (int j = 0; j < data.cols; j++) {
        double val = scaled_data.at<double>(0, j);
        scaled_data.at<double>(0, j) = (val - center) / scale;
    }
    
    return scaled_data;
}

- (cv::Mat)preprocessingPipeline: (const cv::Mat &)data withScale:(double)scale withCenter:(double)center {
    // Flatten matrix using column-major transformation.
    Mat feature_vector =  Mat(data.t()).reshape(1, 1);
    
    Mat scaled_feature_vector = [self transform_scale: feature_vector withScale: scale withCenter: center];
    
    return scaled_feature_vector;
}

- (NSString *)exerciseName: (int) idx{
    return [_labels objectAtIndex: idx];
}

- (NSMutableData*) dataFromMat:(cv::Mat*) image
{
    int matRows = image->rows;
    int matCols = image->cols;
    NSMutableData* data = [[NSMutableData alloc]init];
    unsigned char *pix;
    for (int i = 0; i < matRows; i++)
    {
        for (int j = 0; j < matCols; j++ )
        {
            pix = &image->data[i * matCols + j ];
            [data appendBytes:(void*)pix length:1];
        }
    }
    return data;
}

-  (svm_classifier::classification_result)classify: (const std::vector<fused_sensor_data> &)data{

    auto first_sensor_data = data[0];
    
    // Apply initial preprocessing steps to data.
    Mat preprocessed = [self initial_preprocessing: first_sensor_data.data];
    
    LOG(TRACE) << "Raw input data = "<< std::endl << " "  << preprocessed << std::endl << std::endl;
    
    // Sliding window.
    int numWindows = 0;
    int prediction = -1;
    double overall_prediction[_nrOfClasses];

    for(int i = 0; i + _windowSize <= first_sensor_data.data.rows; i += _stepSize) {
        // Get window expected size.
        Mat window = preprocessed(cv::Range(i, i + _windowSize), cv::Range(0, 3));
        Mat feature_matrix = [self preprocessingPipeline: window withScale: 8000 withCenter: -4000];
        
        // Predict output of the model for new sample
        NSMutableData * windowPrediction = [NSMutableData dataWithLength:sizeof(double)*_nrOfClasses];
        
        NSData *feature_vector = [self dataFromMat: &feature_matrix];
        
        [_model predictByFeatureVector: feature_vector intoPredictionVector: windowPrediction];
        
        // Predict label.
        double * confidenceScores = (double *)windowPrediction.bytes;
        
        //LOG(TRACE) << "Prediction for " << m_exercise_name << ": " << prediction << " with confidence: " << confidenceScores[0] << std::endl;
        
        for(int c=0; c < _nrOfClasses; ++c){
            overall_prediction[c] += confidenceScores[c];
            if(prediction == -1 or overall_prediction[prediction] < overall_prediction[c])  {
                prediction = c;
            }
        }
        numWindows++;
    }
    
    if(prediction >= 0) {
        muvr::svm_classifier::classified_exercise exercise = svm_classifier::classified_exercise([self exerciseName: prediction].cString, -1, 1.0, 1.0, overall_prediction[prediction] / numWindows);
        return svm_classifier::classification_result(muvr::svm_classifier::classification_result::success, std::vector<muvr::svm_classifier::classified_exercise> { exercise }, data);
    } else {
        return svm_classifier::classification_result(muvr::svm_classifier::classification_result::failure, std::vector<muvr::svm_classifier::classified_exercise> { }, data);
    }
}

@end