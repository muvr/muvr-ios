#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import "MRRepetitionEstimator.h"
#import <vector>
#import <experimental/optional>
#include "easylogging++.h"

@implementation MRRepetitionEstimator

// Estimate number of repetitions
- (uint)estimate:(const std::vector<muvr::fused_sensor_data>&)data {
    if (data.empty()) return 0;
    auto firstData = data.front();
    return [self numberOfRepetitions:firstData.data];
}

// Estimate the number of repetition given a multidimensional signal.
- (uint)numberOfRepetitions:(const cv::Mat&)data {
    uint N = data.rows;
    std::vector<std::vector<uint>> peaks;

    for (uint i = 0; i < data.cols; ++i) {
        std::vector<double> rv = std::vector<double>(N);
        for (uint j = 0; j < N; ++j) rv[j] = data.at<int16_t>(j, i);
        std::vector<double> correlation = [self autocorrelation:rv];
        std::vector<uint> peaks_in_dimension = [self findPeaks:correlation];
    
        peaks.push_back(peaks_in_dimension);
    }
    
    uint repetitions = [self guessNumberOfRepetitions:peaks inData: data withMinPeakDistance:30];
    return repetitions;
}

// Autocorrelation of a signal. Calculates the signal of itself over time.
- (std::vector<double>)autocorrelation:(const std::vector<double>&)data{
    size_t filterLength = data.size();
    size_t resultLength = data.size();
    size_t signalLength = data.size() + filterLength - 1;
    std::vector<double> correlation = std::vector<double>(resultLength, 0.0);
    std::vector<double> signal = std::vector<double>(signalLength, 0.0);
    signal.insert(signal.begin(), data.begin(), data.end());
    
    vDSP_convD(signal.data(), vDSP_Stride(1),
               data.data(), vDSP_Stride(1),
               correlation.data(), vDSP_Stride(1),
               vDSP_Length(resultLength),
               vDSP_Length(filterLength));
    
    double max = 2.0 / correlation[0];
    double shift = -1;
    vDSP_vsmsaD(correlation.data(), vDSP_Stride(1),
                &max,
                &shift,
                correlation.data(), vDSP_Stride(1),
                vDSP_Length(correlation.size()));
    
    return correlation;
}

// Find maxima in a signal using a simple pattern approach. Works well for denoised signals.
- (std::vector<uint>)findPeaks:(const std::vector<double>&)data {
    const int nDowns = 1;
    const int nUps = 1;
    std::vector<uint> peaks;

    for (uint i = nDowns; i < data.size() - nUps; ++i) {
        bool isPeak = true;
        for (int j = -nDowns; j < nUps; ++j) {
            if (j < 0) isPeak = isPeak && data[i + j] <  data[i + j + 1];
            else       isPeak = isPeak && data[i + j] >= data[i + j + 1];
        }
        if (isPeak) peaks.push_back(i);
    }
    
    return peaks;
}

// Check if a value is in a margin of another one
- (bool)is_nearly_equal:(int)a with:(int)b inMargin:(double)margin{
    return (1 + margin) * a > b && b > (1 - margin) * a;
}

// Check if a periodic profile is in the margin of another one
- (bool)is_nearly_equal_profile:(PeriodicProfile)a with:(PeriodicProfile)b inMargin:(double)margin{
    return [self is_nearly_equal:a.total_steps with:b.total_steps inMargin:margin] &&
           [self is_nearly_equal:a.total_steps with:b.total_steps inMargin:margin] &&
           [self is_nearly_equal:a.total_steps with:b.total_steps inMargin:margin];
}

// Use peak information and multidimensional signal data to create periodic profiles.
- (std::vector<PeriodicProfile>)constructPeriodicProfiles:(std::vector<uint>)peaks data:(const cv::Mat&)data dimension:(uint)dimension{
    std::vector<PeriodicProfile> inter_peak_heights;
    uint previous_peak_location = 0;
    int previous_height = 0, current_height = 0;
    for (uint i = 0; i < peaks.size(); ++i) {
        PeriodicProfile profile;
        // Count upwards and downwards steps between the last and the current peak
        for(uint j = previous_peak_location; j < peaks[i] - 1; j++) {
            previous_height = data.at<int16_t>(j, dimension);
            current_height = data.at<int16_t>(j+1, dimension);
            int steps = previous_height - current_height;
            if(steps > 0){
                profile.upward_steps += steps;
            } else {
                profile.downward_steps -= steps;
            }
        }
        profile.total_steps = profile.upward_steps + profile.downward_steps;
        inter_peak_heights.push_back(profile);
        previous_peak_location = peaks[i];
    }
    return inter_peak_heights;
}

// Select a median periodic profil.
- (PeriodicProfile)medianPeriodicProfile:(std::vector<PeriodicProfile>)profiles{
    std::vector<PeriodicProfile> elements = profiles;
    PeriodicProfile median;
    size_t size = elements.size();
    
    sort(elements.begin(), elements.end(), [](PeriodicProfile a, PeriodicProfile b){ return a.total_steps < b.total_steps; });
    
    if(size > 0){
        median = elements[size / 2];
    }
    return median;
}

// Select the dimension of the signal that expresses the periodicity of the signal most clearly
- (uint)findMostSignificantDimension:(std::vector<std::vector<uint>>&)peaks inData:(const cv::Mat&)data{
    std::vector<uint> min_peaks = std::vector<uint>(data.rows);
    uint min_idx = 0;
    
    for(uint dimension = 0; dimension < data.cols; ++dimension){
        if(peaks[dimension].size() < min_peaks.size()){
            min_peaks = peaks[dimension];
            min_idx = dimension;
        }
    }
    return min_idx;
}

// Guess the number of repetitions in the passed in data.
- (uint)guessNumberOfRepetitions:(std::vector<std::vector<uint>>&)peaks inData: (const cv::Mat&)data withMinPeakDistance:(uint)distance {
    uint min_idx = [self findMostSignificantDimension:peaks inData:data];
    std::vector<uint> min_peaks = peaks[min_idx];
    std::vector<PeriodicProfile> profiles = [self constructPeriodicProfiles:min_peaks data:data dimension:min_idx];

    PeriodicProfile median_profile = [self medianPeriodicProfile:profiles];
    uint previous_peak_location = 0;
    uint count = 0;

    for (uint i = 0; i < min_peaks.size(); ++i) {
        // We will only count periods that seem to be similar to other periods
        if (min_peaks[i] - previous_peak_location >= distance && [self is_nearly_equal_profile:profiles[i] with:median_profile inMargin:0.5]) {
            count++;
        }
        
        //LOG(DEBUG) << "NR: " << min_peaks[i] << " T "<< profiles[i].total_steps << " D "<< profiles[i].downward_steps << " U "<< profiles[i].upward_steps << " C " << count << std::endl;
        previous_peak_location = min_peaks[i];
    }
    return count;
}

@end
